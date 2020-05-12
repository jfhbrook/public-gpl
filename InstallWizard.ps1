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
  Write-Host "Cackledaemon is already installed, but there might be " -NoNewLine
  Write-Host "updates..!" -ForegroundColor Yellow -NoNewLine
  Write-Host " :)"
  Write-Host "This script can " -NoNewLine
  Write-Host "optionally" -ForegroundColor Green -NoNewLine
  Write-Host " update the Cackledaemon module for the " -NoNewLine
  Write-Host "current user" -ForegroundColor Cyan -NoNewLine
  Write-Host '.'

  $InstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Reinstall the Cackledaemon module the current user. This will install module updates."
  $DontInstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't reinstall the Cackledaemon module. It's already installed, but there may be updates."

  $InstallCackledaemon = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to reinstall Cackledaemon?",
    "Whaddaya think?",
    @($InstallCackledaemonChoice, $DontInstallCackledaemonChoice),
    0
  )
} else {
  Write-Host "Cackledaemon " -NoNewLine
  Write-Host "needs to be installed!" -ForegroundColor Yellow
  Write-Host "This script will install the Cackledaemon module for the " -NoNewLine
  Write-Host "current user" -ForegroundColor Cyan -NoNewLine
  Write-Host "."

  $InstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install the Cackledaemon module for the current user. This is required in order to use Cackledaemon."
  $DontInstallCackledaemonChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't install the Cackledaemon module. This will abort the installation process."

  $InstallCackledaemon = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to install Cackledaemon?",
    "Whaddaya think?",
    @($InstallCackledaemonChoice, $DontInstallCackledaemonChoice),
    0
  )
}
Write-Host ''

if ($InstallCackledaemon) {
  Write-Host 'Installing the Cackledaemon module...'
  Install-Module -Force Cackledaemon
  Write-Host 'All done!'
}

$InstalledModule = Get-InstalledModule 'Cackledaemon' -ErrorAction SilentlyContinue

if (-not $InstalledModule) {
  Write-Host 'Cackledaemon is ' -NoNewLine
  Write-Host 'not installed' -ForegroundColor Red -NoNewLine
  Write-Host ' and the script can not continue.'
  Write-Host 'Have a nice day!'
  Exit
}

Import-Module Cackledaemon

if (Test-Path $CackledaemonWD) {
  Write-Host "$CackledaemonWD already exists - nothing to do here!"
} else {
  Write-Host "Time to initialize " -NoNewLine
  Write-Host $CackledaemonWD -ForegroundColor Yellow -NoNewLine
  Write-Host "!"

  $ModuleDirectory = Split-Path -Path (Get-Module Cackledaemon).Path -Parent
  $StartMenuPath = Join-Path $Env:AppData 'Microsoft\Windows\Start Menu\Programs\Gnu Emacs'
  $ShortcutsCsvPath = Join-Path $ModuleDirectory 'Shortcuts.csv'

  Write-Host "By default, Cackledaemon will " -NoNewLine
  Write-Host "create these shortcuts" -ForegroundColor Green -NoNewLine
  Write-Host " inside the 'GNU Emacs' folder in the user's Start Menu when installing Emacs:"
  Write-Host ''

  Import-Csv -Path $ShortcutsCsvPath | ForEach-Object {
    Write-Host "- " -NoNewLine
    Write-Host ("{0}\{1}.lnk" -f $StartMenuPath, $_.ShortcutName) -ForegroundColor Green -NoNewLine
    Write-Host " -> " -NoNewLine
    Write-Host $_.EmacsBinaryName -ForegroundColor Yellow
  } | Out-Null
  Write-Host ''
  Write-Host "You may " -NoNewLine
  Write-Host "edit this config" -ForegroundColor Cyan -NoNewLine
  Write-Host " at " -NoNewLine
  Write-Host "$CackledaemonWD\Shortcuts.csv" -ForegroundColor Yellow -NoNewLine
  Write-Host " and re-run the Emacs install step at " -NoNewLine
  Write-Host "any time" -ForegroundColor Green -NoNewLine
  Write-Host " to change these shortcuts."

  $InstallShortcutsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Create these shortcuts in the Start Menu. You can edit this CSV and re-run this step at any time."
  $DontInstallShortcutsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't create any shortcuts in the Start Menu at this time. You can create a fresh CSV and re-run this step at any time."

  $NoShortcuts = [boolean]$host.UI.PromptForChoice(
    "Do you want to use these shortcuts?",
    "Whaddaya think?",
    @($InstallShortcutsChoice, $DontInstallShortcutsChoice),
    0
  )
  Write-Host ''

  New-CackledaemonWD -NoShortcuts $NoShortcuts | Out-Null
}

Write-Host "Checking the state of Emacs..."
Write-Host ''

$EmacsCommand = Get-Command 'emacs.exe'

if ($EmacsCommand) {
  if (Test-EmacsExe -ErrorAction Stop) {
    Write-Host "Emacs is already installed but it couldn't hurt to check for " -NoNewLine
    Write-Host "updates..! :)" -ForegroundColor Yellow
    Write-Host "This script can " -NoNewLine
    Write-Host "optionally" -ForegroundColor Green -NoNewLine
    Write-Host " install updates to Emacs for " -NoNewLine
    Write-Host "all users" -ForegroundColor Red -NoNewLine
    Write-Host ". It requires, and will prompt for, " -NoNewLine
    Write-Host "Administrator privileges" -ForegroundColor Cyan -NoNewLine
    Write-Host '.'

    $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Check for and install any available Emacs updates."
    $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't check for Emacs updates. Emacs is already installed, so this is probably OK. You can run this manually at any time by importing the Cackledaemon module and running 'Install-Emacs'."
    $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
      "Do you want to check for updates to Emacs?",
      "Whaddaya think?",
      @($InstallEmacsChoice, $DontInstallEmacsChoice),
      0
    )
  } else {
    Write-Host "An " -NoNewLine
    Write-Host "unmanaged Emacs" -ForegroundColor Red -NoNewLine
    Write-Host " is " -NoNewLine
    Write-Host "already on your `$Path" -ForegroundColor Red -NoNewLine
    Write-Host "! This script will probably cause " -NoNewLine
    Write-Host "surprising behavior" -ForegroundColor Yellow -NoNewLine
    Write-Host " but is " -NoNewLine
    Write-Host "game to try" -ForegroundColor Cyan -NoNewLine
    Write-Host "!"

    $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install a managed Emacs alongside the unmanaged Emacs version already detected. This will likely cause surprising behavior - it is recommended that you read the manual before continuing."
    $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't install a managed Emacs. This is the safest choice, but means that you can't take advantage of Cackledaemon's features. You can run this manually at any time by importing the Cackledaemon module and running 'Install-Emacs'."
    $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
      "Do you want to install a managed Emacs alongside the version of Emacs already installed?",
      "Whaddaya think?",
      @($InstallEmacsChoice, $DontInstallEmacsChoice),
      1
    )
  }
} else {
  Write-Host "Emacs " -NoNewLine
  Write-Host "needs to be installed!" -ForegroundColor Yellow
  Write-Host "This script will install Emacs for " -NoNewLine
  Write-Host "all users" -ForegroundColor Red -NoNewLine
  Write-Host ". It requires, and will prompt for, " -NoNewLine
  Write-Host "Administrator privileges" -ForegroundColor Cyan -NoNewLine
  Write-Host "."

  $InstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install Emacs. This is required in order to use Cackledaemon and Emacs."
  $DontInstallEmacsChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't install Emacs. This will abort the installation process."
  $InstallEmacs = -not [boolean]$host.UI.PromptForChoice(
    "Do you want to install Emacs?",
    "Whaddaya think?",
    @($InstallEmacsChoice, $DontInstallEmacsChoice),
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
  Write-Host 'Emacs is ' -NoNewLine
  Write-Host 'not installed' -ForegroundColor Red -NoNewLine
  Write-Host ' and the script can not continue.'
  Write-Host 'Have a nice day!'
  Exit
}

Write-Host ''
Write-Host "Cackledaemon can also set up the " -NoNewLine
Write-Host "current user's " -ForegroundColor Cyan -NoNewLine
Write-Host " environment by configuring the user's `$Path and `$HOME and by creating shortcuts. This touches the user's " -NoNewLine
Write-Host "registry" -ForegroundColor Yellow -NoNewLine
Write-Host " but doesn't require Administrator privileges."

$InstallEnvironmentChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Set up the user's environment for Emacs. This isn't strictly required but is nice to have."
$DontInstallEnvironmentChoice = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Don't set up the user's environment for Emacs. Emacs will be installed but it will be tough for the user to run."
$InstallEnvironment = -not [boolean]$host.UI.PromptForChoice(
  "Do you want to set up the user environment?",
  "Whaddaya think?",
  @($InstallEnvironmentChoice, $DontInstallEnvironmentChoice),
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
