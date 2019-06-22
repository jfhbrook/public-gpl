# Functions and code based on GLib's gshell library
# See: https://github.com/GNOME/glib/blob/master/glib/gshell.c
#
# Copyright (C) 2019 Joshua Holbrook
# gshell.c Copyright (C) 2000 Red Hat, Inc.
#
# This library is free software you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# Locense as pubished by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTIBIITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, see <http://www.gnu.org/licenses/>.
#
# Missing functions: unquote_string_inplace, ensure_token and delimit_token
# are all inlined into their various call sites.

"""
gshell.py provides the functions g_shell_quote() and g_shell_unquote() to
handle shell-like quoting in strings as in the corresponding functions in
GLib. The function g_shell_parse_argv() parses a string in the same way that
GLib's g_shell_parse_argv() does, which is similar but not quite the same as
the way a POSIX shell (/bin/sh) would.

In general, you should use <https://docs.python.org/3/library/shlex.html> for
this sort of thing, but if your use case involves wanting behavior consistent
with GLib or users of GLib like GNOME or XFCE, this will deliver.
"""


class GShellError(Exception):
    """
    A base exception for all gshell.py errors
    """
    pass


class BadQuotingError(GShellError):
    """
    An exception raised when encountering bad quoting
    """
    pass


class EmptyStringError(GShellError):
    """
    An exception raised when string input is empty
    """
    pass


def g_shell_quote(unquoted_string):
    """
    g_shell_quote:
    @unquoted_string: (type str): a literal string

    Quotes a string so that the shell (/bin/sh) will interpret the quoted
    string to mean @unquoted_string. If you pass a filename to the shell,
    for example, you would want to first quote it with a function like this
    one. The quoting style used is undefined by GLib, but this implementation
    happens to use single quotes, "because the algorithm is cheesier."

    Returns (type str): quoted string
    """

    dest = "'"
    p = 0
    l = len(unquoted_string)  # noqa

    while p < l:
        if unquoted_string[p] == "'":
            dest += "'\\''"
        else:
            dest += unquoted_string[p]

        p += 1

    dest += "'"

    return dest


def g_shell_unquote(quoted_string):
    """
    g_shell_unquote:
    @quoted_string: (type str): shell-quoted string

    Unquotes a string as GLib's gshell.c would, which is as the shell would.
    Only handles quotes; if a string contains file globs, arithmetic operators,
    variables, backticks, redirections, or other special-to-the-shell features,
    the result will be different from the result a real shell would produce
    (the variables, backticks etc will be passed through literally instead of
    being expanded). This function is guaranteed to succeed if applied to the
    result of g_shell_quote(). If it fails, it raises an instance of
    BadQuotingError. The @quoted_string need not actually contain quoted or
    escaped text; g_shell_unquote() simply goes through the string and
    unquotes/escapes anything that the shell would. Both single and double
    quotes are handled, as are escapes including escaped newlines.

    Shell quoting rules are a bit strange. Single quotes preserve the literal
    string exactly. escape sequences are not allowed; not even \\' - if you
    want a ' in the quoted text, you have to do something like 'foo\\''bar'.
    Double quotes allow $, `, ", \\, and newline to be escaped with backslash.
    Otherwise double quotes preserve things literally.

    Returns: (type str): an unquoted string
    """
    end = 0
    start = 0
    l = len(quoted_string)  # noqa
    retval = ''

    # Lord forgive me for what I'm about to do...
    class C_C_C_COMBO_BREAKER(Exception):
        pass

    while start < l:
        while (
            (start < l) and
            not (
                (quoted_string[start] == '"') or
                (quoted_string[start] == "'")
            )
        ):
            if quoted_string[start] == '\\':
                start += 1

                if start < l:
                    if quoted_string[start] != '\n':
                        retval += quoted_string[start]
                    start += 1
            else:
                retval += quoted_string[start]
                start += 1

        if start < l:
            # This corresponds to "unquote_string_inplace" in glib/gshell.c
            # Obviously this doesn't unquote a string in-place
            # Instead, we:
            # * Inline the code so that we can modify the indexes (which we
            #   use instead of pointers
            # * Append to a python string as dest instead of modifying the
            #   source string in-place
            # * Abuse exceptions to simulate how the original procedure uses
            #   return
            try:
                dest = ''
                s = start

                quote_char = quoted_string[s]

                if quote_char not in {'"', "'"}:
                    raise BadQuotingError(
                        "Quoted text doesn't begin with a quotation mark"
                    )

                s += 1

                if quote_char == '"':
                    while s < l:
                        if quoted_string[s] == '"':
                            s += 1
                            end = s

                            raise C_C_C_COMBO_BREAKER()

                        elif quoted_string[s] == '\\':
                            s += 1
                            if quoted_string[s] in '"\\`$\n':
                                dest += quoted_string[s]
                                s += 1
                            else:
                                dest += '\\'
                        else:
                            dest += quoted_string[s]
                            s += 1
                else:
                    while s < l:
                        if quoted_string[s] == "'":
                            s += 1
                            end = s

                            raise C_C_C_COMBO_BREAKER()
                        else:
                            dest += quoted_string[s]
                            s += 1

            except C_C_C_COMBO_BREAKER:
                retval += dest
                start = end
            else:
                raise BadQuotingError(
                    'Unmatched quotation mark in command line or other shell '
                    'quoted text'
                )

    return retval


# Via gshell.c:
#
# > g_parse_argv() does a semi-arbitrary weird subset of the way the shell
# > parses a command line. We don't do variable expansion, don't understand
# > that operators are tokens, don't do tilde expansion, don't do command
# > substitution, no arithmetic expansion, IFS gets ignored, don't do filename
# > globs, don't remove redirection stuff, etc.
# >
# > READ THE UNIX98 SPEC on "Shell Command Language" before changing the
# > behavior of this code.
#
# Well then! (See the gshell.c source for more)
def tokenize_command_line(command_line):
    current_quote = None
    current_token = None
    retval = []
    quoted = False

    l = len(command_line)  # noqa
    i = 0

    while i < l:
        p = command_line[i]

        if current_quote == '\\':
            if p == '\n':
                pass
            else:
                current_token = current_token or ''
                current_token += '\\'
                current_token += p
            current_quote = None
        elif current_quote == '#':
            while i < l and command_line[i] != '\n':
                i += 1

            if i < l:
                p = command_line[i]
            current_quote = None

            if i >= l:
                break
        elif current_quote:
            if (
                (p == current_quote) and
                not ((current_quote == '"') and quoted)
            ):
                current_quote = None
            current_token = current_token or ''
            current_token += p
        else:
            if p == '\n':
                retval.append(current_token)
                current_token = None
            elif p in {' ', '\t'}:
                if current_token:
                    if current_token:
                        retval.append(current_token)
                        current_token = None
            elif p in {"'", '"', '\\'}:
                if p != '\\':
                    current_token = current_token or ''
                    current_token += p
                current_quote = p
            elif p == '#':
                if i == 0:
                    current_quote = p
                else:
                    prior = command_line[i-1]
                    if (
                        (prior == ' ') or
                        (prior == '\n') or
                        (prior == '\0')
                    ):
                        current_quote = p
                    else:
                        current_token = current_token or ''
                        current_token += p
            else:
                current_token = current_token or ''
                current_token += p
        if p != '\\':
            quoted = False
        else:
            quoted = not quoted

        i += 1

    if current_token is not None:
        retval.append(current_token)
    current_token = None

    if current_quote:
        if current_quote == '\\':
            raise BadQuotingError('Text ended just after a "\\" character.')
        else:
            raise BadQuotingError(
                f'Text ended before matching quote was found for '
                f'{current_quote}. (The text was "{command_line}")'
            )

    if not retval:
        raise EmptyStringError(
            'Text was empty (or contained only whitespace)'
        )

    return retval


def g_shell_parse_argv(command_line):
    """
    g_shell_parse_argv:
    @command_line: (type str): command line to parse

    Parses a command line into an argument vector, using the logic in GLib's
    gshell.c, which is intended to work in much the same way the shell would,
    but without many of the xpansions the shell would perform (variable
    expansion, globs, operators, filename expansion, etc. are not supported).
    The results are defined to be the same as those you would get from a UNIX98
    /bin/sh, as long as the input contains none of the unsupported shell
    expansions. If the input does contain such expansions, they are passed
    through literally. Possible exceptions are BadQuotingError and
    EmptyStringError.

    Returns: (type List[str]): a list of args
    """
    return [
        g_shell_unquote(token)
        for token in tokenize_command_line(command_line)
    ]
