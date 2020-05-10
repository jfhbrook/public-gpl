
# Introduction

> Oh-ho-ho! Swirly Photoshop magic! I bet this thing could release some serious
> cackledemons!
> 
> &#x2013; Strong Bad

In recent times I've become a big fan of [Emacs](https://www.gnu.org/software/emacs/). On a really surface level Emacs
is a humble code editor, but the truth is that Emacs is less a code editor and
more of a **framework** for **writing text-based applications**. I like to compare
it to [Node.js](https://nodejs.org) in this regard, which, while really good at being a webserver is
no [NGINX](https://www.nginx.com/), but instead a runtime where you can import lots of tiny pieces of
functionality a la carte to make your own webserver. Any one of these
configurations does exactly this - it installs packages from the internet,
requires them and uses [Emacs Lisp](https://www.gnu.org/software/emacs/manual/html_node/eintr/) to create a complete application. I use a
third party configuration called [Doom Emacs](https://github.com/hlissner/doom-emacs), which uses a package called [evil](https://github.com/emacs-evil/evil)
that makes Emacs pretend to be [vim](https://www.vim.org/) (my prior code editor of choice). In addition
to editing code, I also use Emacs for personal task management, using an Emacs
package called [org-mode](https://orgmode.org/) combined with a process somewhere in between [GTD](https://en.wikipedia.org/wiki/Getting_Things_Done) and
[bullet jouraling](https://en.wikipedia.org/wiki/Bullet_Journal).

I also have a lot of computers and I use Emacs on all of them. One of these
computers happens to run Windows 10 - meaning that I run Emacs on Windows.

Running Emacs in Windows is a bit of a mess. This is because Emacs was written
with \*nix OS's in mind. This meas that in Linux you can casually install it with
your package manager and everything Just Works, and that in OSX you can install
either a [universal binary](https://emacsformacosx.com/) or - if you prefer - [homebrew](https://brew.sh/), and have a more or less
seamless process. Windows, meanwhile, doesn't have a nice installer, environment
configuration is up to interpretation, actually invoking Emacs differs
significantly, and running Emacs as a daemon becomes difficult.

This project, a [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-5.1) module written as a [literate program](https://en.wikipedia.org/wiki/Literate_programming) using [org-babel](https://orgmode.org/worg/org-contrib/babel/),
contains tools for managing Emacs on Windows, namely an ****installation setup
wizard**** and a ****tray icon for managing the Emacs daemon****.


## Getting Started

Cackledaemon includes an installation wizard that will install the Cackledaemon
module off [the PowerShell Gallery](https://www.powershellgallery.com/packages/Cackledaemon) and then walk the user through installing
Emacs, setting up their environment, and installing the tray icon, configuring
it to run when you log into Windows. You can download and run the latest version
of this installer by copying and pasting the following snippet into a PowerShell
window.

    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jfhbrook/cackledaemon/master/Cackledaemon/InstallWizard.ps1')

You don't need to run this as Administrator - Cackledaemon will install
itself for your user and will prompt for Administrator access whenever it needs
to install Emacs system-wide.


## Learning More

The [source code for Cackledaemon](https://github.com/jfhbrook/cackledaemon/blob/master/Cackledaemon.org), a literate program with prose and source code
intermixed, should be readable from top to bottom and contains all the
information someone would need to use it effectively.


## Building Cackledaemon

This project uses [Invoke-Build](https://github.com/nightroman/Invoke-Build) to manage its tasks. Running `Invoke-Build` by
default will clean up old files, run the build and run tests.

    task . Clean, Build, Test

Before running the build, it's a good idea to use `Remove-Item` to clean up old
files, especially if any of the filenames that org-mode is tangling to have
changed. Running `Invoke-Build` without arguments will run this step
automatically, but it can be ran in isolation with `Invoke-Build Clean`.

    task Clean {
      Get-ChildItem './Cackledaemon' | ForEach-Object {
        Remove-Item $_.FullName
      }
      Remove-Item 'README.md' -ErrorAction 'SilentlyContinue'
      Remove-Item 'README.md~' -ErrorAction 'SilentlyContinue'
    }

The build itself can be started in isolation by running `Invoke-Build Build`.

    task Build {
      emacs.exe --batch --load build.el
      Copy-Item 'COPYING' .\Cackledaemon\COPYING -ErrorAction 'SilentlyContinue'
      Remove-Item 'README.md~' -ErrorAction 'SilentlyContinue'
    }

This task will call Emacs in [batch mode](https://www.gnu.org/software/emacs/manual/html_node/elisp/Batch-Mode.html) to tangle this file into the working
module using `org-babel` and export the README. Alternately, you may type `C-c
C-v t` with this file open in Emacs to tangle it and use `org-export-to-file` to
export the README.

    (progn
      (require 'org)
      (require 'ob-tangle)
      (require 'ox-md)
    
      (with-current-buffer (find-file-noselect "Cackledaemon.org")
        (message "Tangling Code...")
        (org-babel-tangle)
        (message "Generating README...")
        (org-export-to-file 'md "README.md"))
      (message "Done."))


## Testing Cackledaemon

Cackledaemon's tests use the [Pester test framework](https://pester.dev/). Each test runs in a test environment
that sets up an isolated environment that writes files to a [test drive](https://pester.dev/docs/usage/testdrive).

    function Initialize-TestEnvironment {
      $Global:OriginalAppData = $Env:AppData
      $Global:OriginalProgramFiles = $Env:ProgramFiles
      $Global:OriginalUserProfile = $Env:UserProfile
      $Global:OriginalModulePath = (Get-Module 'Cackledaemon').Path
    
      $Env:AppData = "$TestDrive\AppData"
      $Env:ProgramFiles = "$TestDrive\Program Files"
    
      $Env:UserProfile = "$TestDrive\UserProfile"
    
      New-Item -Type Directory $Env:AppData
      New-Item -Type Directory $Env:ProgramFiles
      New-Item -Type Directory $Env:UserProfile
    
      Remove-Module Cackledaemon -ErrorAction 'SilentlyContinue'
      Import-Module .\Cackledaemon\Cackledaemon.psm1
    
      $Global:CackledaemonWD = "$TestDrive\Cackledaemon"
      $Global:CackledaemonConfigLocation = "$TestDrive\Cackledaemon\Configuration.ps1"
    
      New-CackledaemonWD
    }
    
    function Restore-StandardEnvironment {
      $Env:AppData = $Global:OriginalAppData
      $Env:ProgramFiles = $Global:OriginalProgramFiles
      $Env:UserProfile = $Global:OriginalUserProfile
    
      Remove-Item -Recurse "$TestDrive\AppData"
      Remove-Item -Recurse "$TestDrive\Program Files"
      Remove-Item -Recurse "$TestDrive\UserProfile"
      Remove-Item -Recurse "$TestDrive\Cackledaemon"
    
      Remove-Module Cackledaemon
    
      if ($Global:OriginalModulePath) {
        Import-Module $Global:OriginalModulePath
      }
    }

The tests will be ran automatically when running `Invoke-Build` by default but
can be started in isolation by running `Invoke-Build Test`. Note that the tests
are ran in a subprocess - this is to help ensure that the state of your
environment isn't inadvertently modified by the tests.

    task Test {
      powershell -Command Invoke-Pester
    }


## Licensing

Cackledaemon is absolutely 100% not a part of GNU Emacs, but **is** similarly
licensed under a GPLv3+ license. This means that Cackledaemon is free software,
as defined by the Free Software Foundation.


# License

Cackledaemon, much like Emacs, is licensed under the terms of the GPL v3 or
newer.

    # Copyright 2020 Josh Holbrook
    #
    # This file is part of Cackledaemon and not a part of Emacs.
    #
    # Cackledaemon is free software: you can redistribute it and/or modify
    # it under the terms of the GNU General Public License as published by
    # the Free Software Foundation, either version 3 of the License, or
    # (at your option) any later version.
    #
    # Cackledaemon is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    # GNU General Public License for more details.
    #
    # You should have received a copy of the GNU General Public License
    # along with Cackledaemon.  if not, see <https://www.gnu.org/licenses/>.

