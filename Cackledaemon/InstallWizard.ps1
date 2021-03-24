# Copyright 2020 Josh Holbrook
#
# This file is part of Cackledaemon and 100% definitely not a part of Emacs.
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

#Requires -Version 5.1

Write-Host 'Welcome to the Cackledaemon install wizard!'
Write-Host ''
Write-Host 'This script will guide you through the process of installing/updating Cackledaemon and Emacs.'
Write-Host ''

$InstalledModule = Get-InstalledModule 'Cackledaemon' -ErrorAction SilentlyContinue

if ($InstalledModule) {
  Write-Host "Cackledaemon is already installed, but there might be " -NoNewline
  Write-Host "updates..!" -ForegroundColor Yellow -NoNewline
  Write-Host " :)"
  Write-Host "This script can " -NoNewline
  Write-Host "optionally" -ForegroundColor Green -NoNewline
  Write-Host " update the Cackledaemon module for the " -NoNewline
  Write-Host "current user" -ForegroundColor Cyan -NoNewline
  Write-Host '.'

  $InstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Reinstall the Cackledaemon module the current user. This will install module updates."
  $DontInstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't reinstall the Cackledaemon module. It's already installed, but there may be updates."

  $InstallCackledaemon = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to reinstall Cackledaemon?",
    "Whaddaya think?",
    @($InstallCackledaemonChoice,$DontInstallCackledaemonChoice),
    0
  )
} else {
  Write-Host "Cackledaemon " -NoNewline
  Write-Host "needs to be installed!" -ForegroundColor Yellow
  Write-Host "This script will install the Cackledaemon module for the " -NoNewline
  Write-Host "current user" -ForegroundColor Cyan -NoNewline
  Write-Host "."

  $InstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Install the Cackledaemon module for the current user. This is required in order to use Cackledaemon."
  $DontInstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't install the Cackledaemon module. This will abort the installation process."

  $InstallCackledaemon = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to install Cackledaemon?",
    "Whaddaya think?",
    @($InstallCackledaemonChoice,$DontInstallCackledaemonChoice),
    0
  )
}
Write-Host ''

if ($InstallCackledaemon) {
  Write-Host 'Installing the Cackledaemon module...'
  Install-Module -Scope CurrentUser -Force Cackledaemon
  Write-Host 'All done!'
}

$InstalledModule = Get-InstalledModule 'Cackledaemon' -ErrorAction SilentlyContinue

if (-not $InstalledModule) {
  Write-Host 'Cackledaemon is ' -NoNewline
  Write-Host 'not installed' -ForegroundColor Red -NoNewline
  Write-Host ' and the script can not continue.'
  Write-Host 'Have a nice day!'
  exit
}

Import-Module Cackledaemon

if (Test-Path $CackledaemonWD) {
  Write-Host "$CackledaemonWD already exists - nothing to do here!"
} else {
  Write-Host "Time to initialize " -NoNewline
  Write-Host $CackledaemonWD -ForegroundColor Yellow -NoNewline
  Write-Host "!"

  $ModuleDirectory = Split-Path -Path (Get-Module Cackledaemon).Path -Parent
  $StartMenuPath = Join-Path $Env:AppData 'Microsoft\Windows\Start Menu\Programs\Gnu Emacs'
  $ShortcutsCsvPath = Join-Path $ModuleDirectory 'Shortcuts.csv'

  Write-Host "By default, Cackledaemon will " -NoNewline
  Write-Host "create these shortcuts" -ForegroundColor Green -NoNewline
  Write-Host " inside the 'GNU Emacs' folder in the user's Start Menu when installing Emacs:"
  Write-Host ''

  Import-Csv -Path $ShortcutsCsvPath | ForEach-Object {
    Write-Host "- " -NoNewline
    Write-Host ("{0}\{1}.lnk" -f $StartMenuPath,$_.ShortcutName) -ForegroundColor Green -NoNewline
    Write-Host " -> " -NoNewline
    Write-Host $_.EmacsBinaryName -ForegroundColor Yellow
  } | Out-Null
  Write-Host ''
  Write-Host "You may " -NoNewline
  Write-Host "edit this config" -ForegroundColor Cyan -NoNewline
  Write-Host " at " -NoNewline
  Write-Host "$CackledaemonWD\Shortcuts.csv" -ForegroundColor Yellow -NoNewline
  Write-Host " and re-run the Emacs install step at " -NoNewline
  Write-Host "any time" -ForegroundColor Green -NoNewline
  Write-Host " to change these shortcuts."

  $InstallShortcutsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Create these shortcuts in the Start Menu. You can edit this CSV and re-run this step at any time."
  $DontInstallShortcutsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't create any shortcuts in the Start Menu at this time. You can create a fresh CSV and re-run this step at any time."

  $NoShortcuts = [boolean]$host.UI.PromptForChoice(
    "Do you want to use these shortcuts?",
    "Whaddaya think?",
    @($InstallShortcutsChoice,$DontInstallShortcutsChoice),
    0
  )
  Write-Host ''

  New-CackledaemonWD -NoShortcuts $NoShortcuts | Out-Null
}

Write-Host "Checking the state of Emacs..."
Write-Host ''

$EmacsCommand = Get-Command 'emacs.exe' -ErrorAction 'silentlyContinue'

if ($EmacsCommand) {
  if (Test-EmacsExe -ErrorAction Stop) {
    Write-Host "Emacs is already installed but it couldn't hurt to check for " -NoNewline
    Write-Host "updates..! :)" -ForegroundColor Yellow
    Write-Host "This script can " -NoNewline
    Write-Host "optionally" -ForegroundColor Green -NoNewline
    Write-Host " install updates to Emacs for " -NoNewline
    Write-Host "all users" -ForegroundColor Red -NoNewline
    Write-Host ". It requires, and will prompt for, " -NoNewline
    Write-Host "Administrator privileges" -ForegroundColor Cyan -NoNewline
    Write-Host '.'

    $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Check for and install any available Emacs updates."
    $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't check for Emacs updates. Emacs is already installed, so this is probably OK. You can run this manually at any time by importing the Cackledaemon module and running 'Install-Emacs'."
    $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
      "Do you want to check for updates to Emacs?",
      "Whaddaya think?",
      @($InstallEmacsChoice,$DontInstallEmacsChoice),
      0
    )
  } else {
    Write-Host "An " -NoNewline
    Write-Host "unmanaged Emacs" -ForegroundColor Red -NoNewline
    Write-Host " is " -NoNewline
    Write-Host "already on your `$Path" -ForegroundColor Red -NoNewline
    Write-Host "! This script will probably cause " -NoNewline
    Write-Host "surprising behavior" -ForegroundColor Yellow -NoNewline
    Write-Host " but is " -NoNewline
    Write-Host "game to try" -ForegroundColor Cyan -NoNewline
    Write-Host "!"

    $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Install a managed Emacs alongside the unmanaged Emacs version already detected. This will likely cause surprising behavior - it is recommended that you read the manual before continuing."
    $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't install a managed Emacs. This is the safest choice, but means that you can't take advantage of Cackledaemon's features. You can run this manually at any time by importing the Cackledaemon module and running 'Install-Emacs'."
    $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
      "Do you want to install a managed Emacs alongside the version of Emacs already installed?",
      "Whaddaya think?",
      @($InstallEmacsChoice,$DontInstallEmacsChoice),
      1
    )
  }
} else {
  Write-Host "Emacs " -NoNewline
  Write-Host "needs to be installed!" -ForegroundColor Yellow
  Write-Host "This script will install Emacs for " -NoNewline
  Write-Host "all users" -ForegroundColor Red -NoNewline
  Write-Host ". It requires, and will prompt for, " -NoNewline
  Write-Host "Administrator privileges" -ForegroundColor Cyan -NoNewline
  Write-Host "."

  $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Install Emacs. This is required in order to use Cackledaemon and Emacs."
  $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't install Emacs. This will abort the installation process."
  $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to install Emacs?",
    "Whaddaya think?",
    @($InstallEmacsChoice,$DontInstallEmacsChoice),
    0
  )
}

if ($InstallEmacs) {
  Write-Host 'Installing Emacs...'
  Install-Emacs
} else {
  Write-Host 'Not installing Emacs.'
}

if (-not (Test-EmacsExe)) {
  Write-Host 'Emacs is ' -NoNewline
  Write-Host 'not installed' -ForegroundColor Red -NoNewline
  Write-Host ' and the script can not continue.'
  Write-Host 'Have a nice day!'
  exit
}

Write-Host ''
Write-Host "Cackledaemon can also set up the " -NoNewline
Write-Host "current user's " -ForegroundColor Cyan -NoNewline
Write-Host " environment by configuring the user's `$Path and `$HOME and by creating shortcuts. This touches the user's " -NoNewline
Write-Host "registry" -ForegroundColor Yellow -NoNewline
Write-Host " but doesn't require Administrator privileges."

$InstallEnvironmentChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Set up the user's environment for Emacs. This isn't strictly required but is nice to have."
$DontInstallEnvironmentChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Don't set up the user's environment for Emacs. Emacs will be installed but it will be tough for the user to run."
$InstallEnvironment = -not [boolean]$host.UI.PromptForChoice(
  "Do you want to set up the user environment?",
  "Whaddaya think?",
  @($InstallEnvironmentChoice,$DontInstallEnvironmentChoice),
  0
)

if ($InstallEnvironment) {
  Write-Host "Setting up the user's environment..."
  Install-EmacsUserEnvironment
  Install-CDApplet
} else {
  Write-Host "Not touching the user's environment."
}
Write-Host "Have a nice day!"
