# InstallerCore
@bugsounet Modules/EXTs installer for MagicMirror² modules

This installer is able to:
 * Make pretty installer
 * check OS
 * check root using
 * minify all sources
 * rebuild node module
 * install apt dependencies

# How use it

## Clone the repository in your home folder
```sh
cd ~
git clone https://github.com/bugsounet/InstallerCore
```
## Go to you module directory
```sh
cd ~/MagicMirror/modules
cd <your_module>
```
## Launch the installer
```sh
~/InstallerCore/install.sh
```

## Let's Start
```
Welcome to @bugsounet Installer
This script will create a pretty installer for your module

Do you want to continue? [Y/n] 
Your choice: 
```
If you want to use it: type `y`

```
No root checking...
Checking EXT-Selfies: bugsounet/bugsounet

Checking OS...
OS Detected: linux-gnu (ubuntu 23.04 x86_64)

Checking jq dependency...
Done

Copy installer Folder...
Done
```
Installer will check no root, OS, install `jq` dependency
and finaly copy the `installer` folder into your module

```
Do you plan to use MagicMirror-rebuild ? [Y/n] 
Your choice: 
```

If your module need electron/magicmirror rebuild: type `y`
in other case: type `n`

```
Do you want to minify your sources ? [Y/n] 
Your choice: 
```
Do you want to minify all sources files for speed up your module ? type : `y`<br>
Note: you can past some file to minify in `components` folder of the module<br>
You don't want to use this feature: type `n`

```
Do you want to add apt dependencies ? [Y/n] 
Your choice: 
```
Your module need some apt packets ? type `y`<br>
in other case: type `n`

Case of need some apt packet (by type `y`)
```
What's dependencies?
```
Just enter your dependencies with space on each packet<br>
Sample:
```
make build-essential nginx fswebcam
```
and press Enter

The installer will modify the `package.json file` and install all needed npm package according to your options<br>
Note: this installer make a save file of your `package.json` file: named `package.json.save`

```
Your Installer is ready!

Try can now your npm install command
Press [Enter] to continue
```

Your module installer is now installed!

/!\ don't forget to commit before use `npm install` because it will minify all sources if you have set this option!
/!\ don't publish minified sources
It's now time to try it with `npm install`

# Installer life cyle

`npm install` will follow this rules:
 * `preinstall`: will install all dependencies (script located in installer/preinstall.sh)
 * `postinstall`: will make post-installation: minify, MagicMirror-rebuild if needed (script located in installer/postinstall.sh)

# Extra-Commands

* `npm run update`: natural new command for updating your module!
* `npm run reset`: will reset all change to last local know source (and un-minify it)
* `npm run clean`: will delete `node_modules` folder and `package-lock.json` file and will be ready for a fresh install
* `npm run rebuild`: [available only with MagicMirror-rebuild option] will force to use MagicMirror-rebuild and reinstall the module (case of new version of MagicMirror)

**This installer is used in all EXTs, Gateway, MMM-GoogleAssistant of @bugsounet**<br>
Happy use,<br>
@bugsounet
