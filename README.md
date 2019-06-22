# gshell.py

A port of GLib's gshell.c to Python 3.

## Install

You should be able to install this via pypi in your environment of choice:

```sh
pip install gshell.py
```

You can then use it by importing from `gshell`:

```py
from gshell import g_shell_parse_argv, g_shell_quote, g_shell_unquote
```

## Development and Tests

I use Conda for development. You can create an environment using the included
`environment.yml` file by running `conda env create`, and then running
`conda activate gshell.py`.

Tasks are via make, and include `test`, `lint`, `clean`, `package` and
`publish`.

## License

This library is available via the same license as GLib, which is the LGPL 2.1
or later. See the LICENSE.txt file for more details.
