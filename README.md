# DVDrip
A bash-based script suite for an easy workflow of ripping a dvd into mp4-files.

## Environment and dependencies
This suite of scripts needs at least the following to be true, with regards to the environment it runs in and the tools/software it has available to it (version numbers are "or greater" as an assumption):
- Windows 11 (cmd.exe and powershell.exe)
- WSL & Ubuntu 24.04 / bash
- Python 3.12.3
- VideoLAN VLC player v.3.0.16 (vlc.exe)
- makemkvcon v.1.18.3 (for Ubuntu)
- ffmpeg v.6.1.1 (for Ubuntu)
- HandBrakeCLI v.1.7.2 (for Ubuntu)

A preset and a preset file needs to be done in the HandBrake GUI before using this script. 

## Install
Clone the repository to your computer in WSL. 
Then set up the paths etc. by copying the settings_template.conf to settings.conf and enter the required paths there.

## Usage
In the script directory:
```
Bash:
./main.sh
```
If you want to provide some info about the disc you are ripping, create a text file called `manualinfo.txt` in the script directory. Details in the settings file for that.


## Author
Jouni Lappalainen (2026)