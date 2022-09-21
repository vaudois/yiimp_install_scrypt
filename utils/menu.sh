#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by Vaudois for crypto use...
#####################################################

source /etc/functions.sh
cd $HOME/utils/daemon_builder

RESULT=$(dialog --stdout --nocancel --default-item 1 --title "Daemon Installer v0.1" --menu "Choose one" -1 60 8 \
' ' "- New and existing Daemon builds and upgrade -" \
1 "Build New Coin Daemon from Source Code" \
2 "Upgrade an Existing Coin Daemon" \
' ' "- If your last coin failed to build try this -" \
3 "Daemon Build Failed - Help!" \

4 "Exit")

if [ $RESULT = ]
then
bash $(basename $0) && exit;
fi

if [ $RESULT = 1 ]
then
clear;
cd $HOME/utils/daemon_builder
source menu2.sh;
fi

if [ $RESULT = 2 ]
then
clear;
cd $HOME/utils/daemon_builder
source menu3.sh;
fi

if [ $RESULT = 3 ]
then
clear;
cd $HOME/utils/daemon_builder
source errors.sh;
fi

if [ $RESULT = 4 ]
then
clear;
exit;
fi
