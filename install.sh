#!/bin/bash
# pretty installer
# @bugsounet
# 23/07/2023

#--------------
# Common utils
#  Bugsounet
#--------------

# user's platform (linux, osx)
platform=

# user's architecture (armv7l, x86_64)
arch=

# user's OS name (raspbian, ubuntu, Mac OS X...)
os_name=

#check OS
Installer_checkOS () {
  case "$OSTYPE" in
    linux*)   platform="linux"
              arch="$(uname -m)"
              os_name="$(cat /etc/*release | grep ^ID= | cut -f2 -d=)"
              os_version="$(cat /etc/*release | grep ^VERSION_ID= | cut -f2 -d= | tr -d '"')"
              ;;
    darwin*)  platform="osx"
              arch="$(uname -m)"
              os_name="$(sw_vers -productName)"
              os_version="$(sw_vers -productVersion)"
              ;;
    *)        Installer_error "$OSTYPE is not a supported platform"
              exit 0;;
  esac
}

Installer_update_dependencies () {
  local missings=()
  for package in "${dependencies[@]}"; do
      Installer_is_installed "$package" || missings+=($package)
  done
  if [ ${#missings[@]} -gt 0 ]; then
    Installer_warning "Updating package..."
    for missing in "${missings[@]}"; do
      Installer_error "Missing package: $missing"
    done
    Installer_info "Installing missing package..."
    Installer_update || exit 255
    Installer_install ${missings[@]} || exit 255
  fi
}

# color codes
_reset="\033[0m"
_red="\033[91m"
_orange="\033[93m"
_green="\033[92m"
_gray="\033[2m"
_blue="\033[94m"
_cyan="\033[96m"
_pink="\033[95m"

# Display a message in color
# $1 - message to display
# $3 - color to use
Installer_message() {
  echo -e "$3$1$_reset"
}

# Displays question in cyan
Installer_question () { Installer_message "$1" "Question" "$_cyan" 1>&2 ;}

# Displays a error in red
Installer_error() { Installer_message "$1" "Error" "$_red" 1>&2 ;}

# Displays a warning in yellow
Installer_warning() { Installer_message "$1" "Warning" "$_orange" ;}

# Displays a success in green
Installer_success() { Installer_message "$1" "Success" "$_green" ;}

# Displays an information in blue
Installer_info() { Installer_message "$1" "Info" "$_blue" ;}

# Asks user to press enter to continue
Installer_press_enter_to_continue () {
  Installer_question "Press [Enter] to continue"
  read
}

# Exit
Installer_exit () {
  echo
  Installer_success "$1"
  Installer_press_enter_to_continue

  # reset font color
  echo -e "$_reset\n"

  exit
}

# YesNo prompt from the command line
Installer_yesno () {
  while true; do
    Installer_question "$1 [Y/n] "
    read -n 1 -p "$(echo -e $_cyan"Your choice: "$_reset)"
    echo # new line
    [[ $REPLY =~ [Yy] ]] && return 0
    [[ $REPLY =~ [Nn] ]] && return 1
  done
}

#  Installer_update
Installer_update () {
  sudo apt-get update -y || exit 255
}

# indicates if a package is installed
#
# $1 - package to verify
Installer_is_installed () {
  #hash "$1" 2>/dev/null || (apt-cache policy "$1" 2>/dev/null | grep -q "Installed")
  hash "$1" 2>/dev/null || (dpkg -s "$1" 2>/dev/null | grep -q "installed")
}

# install packages, used for dependencies
#
# $@ - list of packages to install
Installer_install () {
  sudo apt-get install -y $@ || exit 255
  sudo apt-get clean || exit 255
}

# remove packages, used for uninstalls
#
# $@ - list of packages to remove
Installer_remove () {
  sudo apt-get autoremove --purge $@ || exit 255
}

Installer_chk () {
  CHKUSER=$(stat -c '%U' $1)
  CHKGROUP=$(stat -c '%G' $1)
  if [ $CHKUSER == "root" ] || [ $CHKGROUP == "root" ]; then
     Installer_error "Checking $2: $CHKUSER/$CHKGROUP"
     exit 255
  fi
  Installer_success "Checking $2: $CHKUSER/$CHKGROUP"
}

########### MAIN ###########
rm -f package.json.tmp
rebuild=1
minify=1
options=""
dep=1

Installer_info "Welcome to @bugsounet Installer"
Installer_info "This script will create a pretty installer for your module"
echo
Installer_yesno "Do you want to continue?" || exit
echo

if [ ! -f package.json ]; then
  Installer_error "Error: package.json file not found!"
  echo
  exit 255
else 
  cp package.json package.json.save
fi

Installer_module="$(grep -Eo '\"name\"[^,]*' ./package.json | grep -Eo '[^:]*$' | awk  -F'\"' '{print $2}')"
if [ ! $Installer_module ]; then
 Installer_error "Error: name of the module not found in package.json"
 exit 255
fi

# Check not run as root
Installer_info "No root checking..."
if [ "$EUID" -eq 0 ]; then
  Installer_error "npm install must not be used as root"
  exit 255
fi

Installer_chk "$(pwd)/" "$Installer_module"
echo

# Check platform compatibility
Installer_info "Checking OS..."
Installer_checkOS
if  [ "$platform" == "osx" ]; then
  Installer_error "OS Detected: $OSTYPE ($os_name $os_version $arch)"
  Installer_error "Automatic installation is not included"
  echo
  exit 255
else
  if  [ "$os_name" == "raspbian" ] && [ "$os_version" -lt 11 ]; then
    Installer_error "OS Detected: $OSTYPE ($os_name $os_version $arch)"
    Installer_error "Unfortunately, this installer is not compatible with your OS"
    Installer_error "Try to update your OS to the lasted version of raspbian"
    echo
    exit 255
  else
    Installer_success "OS Detected: $OSTYPE ($os_name $os_version $arch)"
  fi
fi
echo

dependencies=(jq)
Installer_info "Checking jq dependency..."
Installer_update_dependencies || exit 255
Installer_success "Done"
echo

Installer_info "Copy installer Folder..."
{
  cp -R ~/InstallerCore/installer .
} || exit 255
Installer_success "Done"
echo

(Installer_yesno "Do you plan to use MagicMirror-rebuild ?") || rebuild=0
(Installer_yesno "Do you want to minify your sources ?") || minify=0
if [[ $minify == 1 ]]; then
 options=" -m"
fi
if [[ $rebuild == 1 ]]; then
 options+=" -r"
fi
(Installer_yesno "Do you want to add apt dependencies ?") || dep=0
if [[ $dep == 1 ]]; then
  Installer_warning "What's dependencies?"
  read dependencies
fi
echo

if [[ $minify == 1 ]]; then
  Installer_info "Install needed npm library (glob esbuild)"
  { 
    npm install glob@10 esbuild@0.18
  } || exit 255
  Installer_success "Done"
else
  Installer_info "Remove npm library (glob esbuild)"
  { 
    npm remove glob esbuild
  } || exit 255
  Installer_success "Done"
fi
echo

if [[ $rebuild == 1 ]]; then
  Installer_info "Install npm magicmirror-rebuild library"
  {
    npm install magicmirror-rebuild
  } || exit 255
  Installer_success "Done"
else
  Installer_info "Remove npm magicmirror-rebuild library"
  {
    npm remove magicmirror-rebuild
  } || exit 255
  Installer_success "Done"
fi
echo

Installer_info "Create preinstall..."
{
  if [[ $dep == 1 ]]; then
    export depsTmp=$dependencies
    jq --arg marks "'" --arg preinstaller 'installer/preinstall.sh -d ' '.scripts.preinstall= $preinstaller + $marks + env.depsTmp + $marks' package.json >> package.json.tmp
    export -n depsTmp
  else
    jq '.scripts.preinstall= "installer/preinstall.sh"' package.json >> package.json.tmp
  fi
  mv package.json.tmp package.json
} || exit 255
Installer_success "Done"
echo

Installer_info "Create postinstall..."
{
  if [[ $rebuild == 1 ]] && [[ $minify == 1 ]]; then
    jq '.scripts.postinstall= "installer/postinstall.sh -r -m"' package.json >> package.json.tmp
  fi
  if [[ $rebuild == 0 ]] && [[ $minify == 1 ]]; then
    jq '.scripts.postinstall= "installer/postinstall.sh -m"' package.json >> package.json.tmp
  fi
  if [[ $rebuild == 1 ]] && [[ $minify == 0 ]]; then
    jq '.scripts.postinstall= "installer/postinstall.sh -r"' package.json >> package.json.tmp
  fi
  if [[ $rebuild == 0 ]] && [[ $minify == 0 ]]; then
    jq '.scripts.postinstall= "installer/postinstall.sh"' package.json >> package.json.tmp
  fi
  mv package.json.tmp package.json
} || exit 255
Installer_success "Done"
echo

Installer_info "Create update..."
{
  jq '.scripts.update= "installer/update.sh"' package.json >> package.json.tmp
  mv package.json.tmp package.json
} || exit 255
Installer_success "Done"
echo

if [[ $rebuild == 1 ]]; then
  Installer_info "Create rebuild..."
  {
    jq '.scripts.rebuild= "installer/rebuild.sh"' package.json >> package.json.tmp
    mv package.json.tmp package.json
  } || exit 255
  Installer_success "Done"
  echo
fi

Installer_info "Create reset tool..."
{
  jq '.scripts.reset= "git reset --hard"' package.json >> package.json.tmp
  mv package.json.tmp package.json
} || exit 255
Installer_success "Done"
echo

Installer_info "Create clean tool..."
{
  jq '.scripts.clean= "rm -rf node_modules package-lock.json"' package.json >> package.json.tmp
  mv package.json.tmp package.json
} || exit 255
Installer_success "Done"
echo

Installer_warning "Your old package.json file as be saved to package.json.save"
Installer_warning "Don't forget so delete your save file if needed!"
echo
Installer_success "Your Installer is ready!"
Installer_exit "Try can now your npm install command"

