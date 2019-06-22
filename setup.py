# -*- coding: utf-8 -*-

from os import path
from setuptools import find_packages, setup

setup(
    name="gshell.py",
    version="0.0.1",
    packages=find_packages(),
    description="A straight port of glib/gshell.c to Python",
    author="Joshua Holbrook",
    author_email="josh.holbrook@gmail.com",
    url="https://github.com/jfhbrook/gshell.py",
    keywords=[
        "glib", "gshell", "shell", "shell quote", "shell unquote",
        "g_shell_quote", "g_shell_unquote", "g_shell_parse_argv"
    ],
    classifiers=[
        "Programming Language :: Python",
        "Development Status :: 4 - Beta",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3.7",
        "License :: OSI Approved :: GNU General Public License v2 or later (GPLv2+)",  # noqa
        "Topic :: System :: Shells"
    ]
)
