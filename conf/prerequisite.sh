#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# Modified by Vaudois
#####################################################

echo
echo
echo -e "$CYAN => Check prerequisite : $COL_RESET"
echo

if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/' `" == "Ubuntu 18.04 LTS" ]; then
  DISTRO=18
  sudo chmod g-w /etc /etc/default /usr
else [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/' `" != "Ubuntu 16.04 LTS" ];
  DISTRO=16
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
