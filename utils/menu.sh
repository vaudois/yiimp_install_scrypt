#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by Vaudois
#####################################################

FUNC=/etc/functionscoin.sh
if [[ ! -f "$FUNC" ]]; then
	source /etc/functions.sh
else
	source /etc/functionscoin.sh
fi

source ${absolutepath}/${installtoserver}/conf/info.sh

cd ${absolutepath}/${installtoserver}/daemon_builder

RESULT=$(dialog --stdout --nocancel --default-item 1 --title " Coin Setup ${VERSION} " --menu "Choose one" -1 60 8 \
1 "Build New Coin Daemon from Source Code" \
2 "Add Coin to Dedicated Port and run stratum" \
3 "Update new Stratum" \
' ' "- Upgrade an Existing new Version of this Srypt -" \
4 "Updrade this scrypt" \

5 Exit)

if [ $RESULT = ]
then
bash $(basename $0) && exit;
fi

if [ $RESULT = 1 ]
then
clear;
cd ${absolutepath}/${installtoserver}/daemon_builder
source menu1.sh;
fi

if [ $RESULT = 2 ]
then
clear;
cd ${absolutepath}/${installtoserver}/daemon_builder
source menu2.sh;
fi

if [ $RESULT = 3 ]
then
clear;
cd ${absolutepath}/${installtoserver}/daemon_builder
source menu3.sh;
fi

if [ $RESULT = 4 ]
then
clear;
cd ${absolutepath}/${installtoserver}/daemon_builder
source menu4.sh;
fi

if [ $RESULT = 5 ]
then
clear;
exit;
fi
