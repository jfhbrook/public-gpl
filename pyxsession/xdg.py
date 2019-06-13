from collections import defaultdict
import os
import os.path
import shutil
from pyxsession.gshell import g_shell_parse_argv
from pyxsession.util.decorators import representable
from xdg.BaseDirectory import load_first_config, xdg_config_dirs
from xdg.Exceptions import ParsingError, ValidationError
from xdg.DesktopEntry import DesktopEntry

XDG_RESOURCE = 'pyxsession'

XDG_AUTOSTART_DIRS = [
    os.path.join(base, 'autostart')
    for base in xdg_config_dirs
]


def config_basedir(resource=XDG_RESOURCE):
    return load_first_config(resource)


@representable([
    'fullpath',
    'filename',
    'overrides',
    'entry',
    'parsed',
    'parse_exc',
    'validated',
    'validate_exc',
    'exec_parsed',
    'exec_parse_exc',
    'exec',
    'is_application',
    'is_hidden',
    'only_show_in',
    'not_show_in',
    'dbus_activatable',
    'runtime_path'
])
class AutostartEntry:
    def __init__(self, fullpath):
        """
        See: https://specifications.freedesktop.org/autostart-spec/autostart-spec-0.5.html#idm140434866991296
        """
        self.fullpath = fullpath
        self.filename = os.path.basename(fullpath)
        self.overrides = []

        try:
            self.entry = DesktopEntry(fullpath)
            self.parsed = True
        except ParsingError as exc:
            self.parsed = False
            self.parse_exc = exc
            self.validated = False
            self.exec_parsed = False
        else:
            try:
                self.entry.validate()
                self.validated = True
            except ValidationError as exc:
                self.validated = False
                self.validate_exc = exc

            try:
                # TODO: The freedesktop specification allows for %-encoded
                # substitution variables. This logic is based on what
                # xfce4-session does, which is use gshell's args parser.
                # It's believed that the gshell parser is a de facto
                # reference implementation for the rest of the rules and
                # likely that because of the lack of a use case for file
                # or url substitution that this is actually basically how
                # this works elsewhere.
                #
                # See also:
                # - https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
                # - https://github.com/xfce-mirror/xfce4-session/blob/0a915310582803296fbfb075e1ea1c045b20bfcc/xfce4-session/xfsm-global.c#L397
                # - https://github.com/xfce-mirror/libxfce4ui/blob/master/libxfce4ui/xfce-spawn.c#L564
                #
                # See the gshell module for more information.
                self.exec = g_shell_parse_argv(self.entry.getExec())
                self.exec_parsed = True
            except GShellError as exc:
                self.exec_parsed = False
                self.exec_parse_exc = exc

    def register_overridden_file(fullpath):
        self.overrides.append(fullpath)

    @property
    def is_application(self):
        if self.parsed:
            return self.entry.getType() == 'Application'
        else:
            return False

    @property
    def is_hidden(self):
        if self.parsed:
            return self.entry.getHidden()
        else:
            return True

    @property
    def only_show_in(self):
        if not self.parsed:
            return None
        return self.entry.getOnlyShowIn()

    @property
    def not_show_in(self):
        if not self.parsed:
            return None
        return self.entry.getNotShowIn()

    def should_show_in(self, show_in):
        if (
            (not self.parsed) or
            (self.only_show_in and self.not_show_in) or
            (show_in in self.not_show_in)
        ):
            return False

        if self.only_show_in and self.not_show_in:
            return False

        if show_in in self.not_show_in:
            return False

        if self.only_show_in:
            return show_in in self.only_show_in

        return True

    @property
    def dbus_activatable(self):
        if not self.parsed:
            return False

        return self.entry.get('DBusActivatable', type='boolean')

    @property
    def runtime_path(self):
        if not self.parsed:
            return None
        return self.entry.getPath() or None

    def passes_try_exec(self):
        if not self.parsed:
            return False

        try_exec = self.entry.getTryExec()

        if not try_exec:
            return True

        return bool(shutil.which(try_exec))

    def should_autostart(self, environment_name):
        return all([
            self.parsed,
            self.is_application,
            self.exec_parsed,
            not self.is_hidden,
            not self.dbus_activatable,
            self.should_show_in(environment_name),
            self.passes_try_exec()
        ])


@representable(['entries'])
class AutostartEntrySet:
    def __init__(self):
        self.entries = []

    def add_entry(self, entry):
        self.entries.append(entry)

    def coalesce(self, *, skip_unparsed, skip_invalid):
        for entry in self.entries:
            parsed = entry.parsed and entry.exec_parsed
            valid = entry.validated

            if (
                (not parsed and skip_unparsed)
                or
                (not valid and skip_invalid)
            ):
                continue

            return entry

        return None


def _load_autostart_dir(dirpath):
    try:
        filenames = os.listdir(dirpath)
    except FileNotFoundError as exc:
        # TODO: Logging
        print(exc)
        return

    for filename in filenames:
        yield AutostartEntry(os.path.join(dirpath, filename))


def _load_autostart(dirs):
    # Based on the logic described in:
    # https://specifications.freedesktop.org/autostart-spec/autostart-spec-0.5.html#idm140434866702736
    configuration_sets = defaultdict(AutostartEntrySet)

    for dirname in dirs:
        for entry in _load_autostart_dir(dirname):
            configuration_sets[entry.filename].add_entry(entry)

    return configuration_sets


@representable([
    'directories',
    'environment_name',
    'all_files',
    'autostart_entries'
])
class AutostartConfiguration:
    def __init__(self, config):
        self.directories = config['autostart']['directories']
        self.environment_name = config['autostart']['environment_name']

        self.entry_sets = _load_autostart(self.directories)

        self.autostart_entries = dict()

        for filename, entry_set in self.entry_sets.items():
            entry = entry_set.coalesce(
                skip_unparsed=config['autostart']['skip_unparsed'],
                skip_invalid=config['autostart']['skip_invalid']
            )
            if entry.should_autostart(self.environment_name):
                self.autostart_entries[filename] = entry
