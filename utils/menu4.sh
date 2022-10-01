#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by Vaudois
# Updrade this scrypt
#####################################################


FUNC=/etc/functionscoin.sh
if [[ ! -f "$FUNC" ]]; then
	source /etc/functions.sh
else
	source /etc/functionscoin.sh
fi

source ${absolutepath}/${installtoserver}/conf/info.sh

message_box " Updating This script " \
"Check if this scrypt needs update.
\n\nYou are currently using version ${VERSION}"

cd ~
clear

sudo curl https://raw.githubusercontent.com/vaudois/install_DmcAddpStrm/master/bootstrap.sh | bash

clear

echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$RED    Thank you using this scrpt Updating is Finish!				 				$COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
exit

