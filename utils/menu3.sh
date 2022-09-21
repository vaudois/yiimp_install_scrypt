#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by afiniel for crypto use...
#####################################################


FUNC=/etc/functionscoin.sh
if [[ ! -f "$FUNC" ]]; then
	source /etc/functions.sh
else
	source /etc/functionscoin.sh
fi

cd absolutepath/utils/daemon_builder

RESULT=$(dialog --stdout --title "Daemon Builder Coin" --menu "Choose one" -1 60 4 \
1 "Update Berkeley 4.x Coin with autogen file" \
2 "Update Berkeley 5.x Coin with autogen file" \
3 "Update Coin with makefile.unix file" \

4 Exit)

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
' | sudo -E tee absolutepath/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source upgrade.sh;
fi

if [ $RESULT = 2 ]
then
clear;
echo '
autogen=true
berkeley="5.3"
' | sudo -E tee absolutepath/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source upgrade.sh;
fi

if [ $RESULT = 3 ]
then
clear;
echo '
autogen=false
' | sudo -E tee absolutepath/utils/daemon_builder/.my.cnf >/dev/null 2>&1;
source upgrade.sh;
fi

if [ $RESULT = 4 ]
then
clear;
exit;
fi
