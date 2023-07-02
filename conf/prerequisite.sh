#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# Modified by Vaudois
#####################################################

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

echo
echo -e "$CYAN => Check prerequisite : $COL_RESET"

if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/' `" == "Ubuntu 18.04 LTS" ]; then
	DISTRO=18
 	echo -E "$YELLOW WARRING$RED php7.3 not supported on Ubuntu 18.*"
  	sleep 7
	sudo chmod g-w /etc /etc/default /usr
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/' `" == "Ubuntu 16.04 LTS" ]; then
  DISTRO=16
    echo -e "$RED This Script not supports on distro ${DISTRO} This run on Ubuntu 18.04 LTS and Ubuntu 20.04 LTS $COL_RESET"
    echo -e "$RED Stop installation now! $COL_RESET"
	exit
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/20\.04\.[0-9]/20.04/' `" == "Ubuntu 20.04 LTS" ]; then
	DISTRO=20
	sudo chmod g-w /etc /etc/default /usr
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/22\.04\.[0-9]/22.04/' `" == "Ubuntu 22.04 LTS" ]; then
	DISTRO=22
    echo -e "$RED This Script not supports on distro ${DISTRO} This run on Ubuntu 18.04 LTS and Ubuntu 20.04 LTS $COL_RESET"
    echo -e "$RED Stop installation now! $COL_RESET"
	exit
  #sudo chmod g-w /etc /etc/default /usr
fi

ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
  if [ -z "$ARM" ]; then
    echo -e "$RED YiimP Install Script only supports x86_64 and will not work on any other architecture, like ARM or 32 bit OS. $COL_RESET"
    echo -e "$RED Your architecture is $ARCHITECTURE $COL_RESET"
    exit
  fi
fi

echo -e "$GREEN Done...$COL_RESET"
