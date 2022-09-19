#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by afiniel for crypto use...
#####################################################

source /etc/functions.sh
cd $HOME/utils/daemon_builder

RESULT=$(dialog --stdout --title "Daemon Builder Coin" --menu "Choose one" -1 60 7 \
1 "Install Berkeley 4.x Coin with autogen file" \
2 "Install Berkeley 5.1 Coin with autogen file" \
3 "Install Berkeley 5.3 Coin with autogen file" \
4 "Install Berkeley 6.2 Coin with build.sh file" \
5 "Install Coin with makefile.unix file" \
6 "Install Coin with CMake file" \

7 Exit)

if [ $RESULT = ]
then
exit;
fi

if [ $RESULT = 1 ]
then
clear;
echo '
autogen=true
berkeley="4.8"
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 2 ]
then
clear;
echo '
autogen=true
berkeley="5.1"
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 3 ]
then
clear;
echo '
autogen=true
berkeley="5.3"
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 4 ]
then
clear;
echo '
autogen=true
berkeley="6.2"
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 5 ]
then
clear;
echo '
autogen=false
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 6 ]
then
clear;
echo '
autogen=false
cmake=true
' | sudo -E tee $HOME/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source source.sh;
fi

if [ $RESULT = 7 ]
then
clear;
exit;
fi
