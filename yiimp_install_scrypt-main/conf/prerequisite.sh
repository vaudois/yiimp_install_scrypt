#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# Modified by Vaudois
# Further modified to support Ubuntu 20.04 and 22.04 without Apache
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
 
if [ "$(lsb_release -rs)" == "20.04" ]; then
    DISTRO=20
    sudo chmod g-w /etc /etc/default /usr
elif [ "$(lsb_release -rs)" == "22.04" ]; then
    DISTRO=22
    sudo chmod g-w /etc /etc/default /usr
else
    echo -e "$RED This script only supports Ubuntu 20.04 LTS and Ubuntu 22.04 LTS $COL_RESET"
    echo -e "$RED Your Ubuntu version: $(lsb_release -rs) $COL_RESET"
    echo -e "$RED Stop installation now! $COL_RESET"
    exit 1
fi
 
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
    if [ -z "$ARM" ]; then
        echo -e "$RED YiimP Install Script only supports x86_64 and will not work on any other architecture, like ARM or 32 bit OS. $COL_RESET"
        echo -e "$RED Your architecture is $ARCHITECTURE $COL_RESET"
        exit 1
    fi
fi
 
echo -e "$GREEN Prerequisites check completed. $COL_RESET"
echo -e "$CYAN Installing on Ubuntu $DISTRO.04 LTS ($ARCHITECTURE) $COL_RESET"