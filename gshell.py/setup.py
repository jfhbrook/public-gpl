# -*- coding: utf-8 -*-

from os import path
from setuptools import find_packages, setup

README_md = path.join(path.abspath(path.dirname(__file__)), 'README.md')

with open(README_md, 'r') as f:
    long_description = f.read()

setup(
    name="gshell.py",
    version="0.0.2",
    packages=find_packages(),
    description="A straight port of glib/gshell.c to Python",
    long_description=long_description,
    long_description_content_type="text/markdown",
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
