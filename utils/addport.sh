#!/usr/bin/env bash

source /etc/functions.sh
#####################################################
# Dedicated Port config generator
# Created by Vaudois for DaemonBuilder coin
# This generator will modify the main algo.conf file
# Create the new coin.algo.conf file
# And update the stratum start file
#####################################################

clear

# Generate random open PORT
function EPHYMERAL_PORT(){
    LPORT=2768;
    UPORT=6999;
    while true; do
        MPORT=$[$LPORT + ($RANDOM % $UPORT)];
        (echo "" >/dev/tcp/127.0.0.1/${MPORT}) >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo $MPORT;
            return 0;
        fi
    done
}

coinport=$(EPHYMERAL_PORT)

cd /var/stratum/config
echo -e "$YELLOW Thanks for using the addport script by Vaudois. $COL_RESET"
echo
echo -e "$YELLOW addport will randomly selects an open port for the coin between ports 2768 and 6999 and open the port in UFW. $COL_RESET"
echo -e "$YELLOW It will also create a new symbol.algo.conf in $RED /var/stratum/config $COL_RESET"
echo -e "$YELLOW and will create a new stratum.symbol run file in $RED /usr/bin. $COL_RESET"
echo

echo
echo -e "$RED Make sure coin symbol is all UPPER case.$COL_RESET"
read -e -p "Please enter the coin SYMBOL : " coinsymbol
echo ""
echo -e "$RED Make sure algo is in all lower case and a valid algo in yiimp.$COL_RESET"
read -e -p "Please enter the coin algo : " coinalgo
echo ""
read -e -p "Would you like to set a minimum nicehash value for this stratum? (y/n) : " nicehash
if [[ ("$nicehash" == "y" || "$nicehash" == "Y" || "$nicehash" == "yes" || "$nicehash" == "YES") ]]; then
read -e -p "Please enter a whole value, example: 750000 : " nicevalue
fi

# Make the coin symbol lower case
coinsymbollower=${coinsymbol,,}
# make sure algo is lower as well since we are Here
coinalgo=${coinalgo,,}
# and might as well make sure the symbol is upper case
coinsymbol=${coinsymbol^^}

# Make sure the stratum.symbol config doesnt exist and that the algo file does.
if [ -f /var/stratum/config/stratum.${coinsymbollower} ]; then
  read -r -e -p "A file for ${coinsymbol} already exists. Are you sure you want to overwrite? A new port will be generated and you will need to update your coind.conf blocknotify line (y/n) : " overwrite
  if [[ ("$overwrite" == "n" || "$overwrite" == "N" || "$overwrite" == "no" || "$overwrite" == "NO") ]]; then
    echo -e "$RED Exiting... $COL_RESET"
    exit 0
  fi
if [ ! -f /var/stratum/config/$coinalgo.conf ]; then
  echo -e "$YELLOW Sorry that algo config file doesn't exist in $RED /home/crypto-data/yiimp/site/stratum/config/ $YELLOW please double check and try again. $COL_RESET"
  exit 0
fi
fi

# Prevent duplications from people running addport multiple times for the same coin...Also known as asshats...
if [ -f /var/stratum/config/$coinsymbollower.$coinalgo.conf ]; then
  if [[ ("$overwrite" == "y" || "$overwrite" == "Y" || "$overwrite" == "yes" || "$overwrite" == "YES") ]]; then
    # Insert the port in to the new symbol.algo.conf
    sed -i '/port/c\port = '${coinport}'' $coinsymbollower.$coinalgo.conf
    echo -e "$YELLOW Port updated! Remeber to update your blocknotify line!! $COL_RESET"
  fi
else
# Since this is a new symbol we are going to add it to the other conf files first.
# First we need to check if this is the first time addport has been ran
files=(*.$coinalgo.conf)
if [ -e "${files[0]}" ]; then
for r in *.$coinalgo.conf; do
  if ! grep -Fxq "exclude = ${coinsymbol}" "$r"; then
    sed -i -e '$a\
[WALLETS]\
exclude = '${coinsymbol}'' "$r"
fi
done
fi
# Copy the default algo.conf to the new symbol.algo.conf
  cp -r $coinalgo.conf $coinsymbollower.$coinalgo.conf
# Insert the port in to the new symbol.algo.conf
  sed -i '/port/c\port = '${coinport}'' $coinsymbollower.$coinalgo.conf
# If setting a nicehash value
if [[ ("$nicehash" == "y" || "$nicehash" == "Y" || "$nicehash" == "yes" || "$nicehash" == "YES") ]]; then
  sed -i -e '/difficulty =/a\
nicehash = '${nicevalue}'' $coinsymbollower.$coinalgo.conf
fi
# Insert the include in to the new symbol.algo.conf
  sed -i -e '$a\
[WALLETS]\
include = '${coinsymbol}'' $coinsymbollower.$coinalgo.conf
fi

#Again preventing asshat duplications...
if ! grep -Fxq "exclude = ${coinsymbol}" "$coinalgo.conf"; then
# Insert the exclude in to algo.conf
  sed -i -e '$a\
[WALLETS]\
exclude = '${coinsymbol}'' $coinalgo.conf
else
  echo -e "$YELLOW ${coinsymbol} is already in $coinalgo.conf, skipping... Which means you are trying to run this multiple times for the same coin. $COL_RESET"
fi

# New coin stratum start file
echo '#####################################################
# Source code from https://codereview.stackexchange.com/questions/55077/small-bash-script-to-sta$
# Updated by Vaudois for Daemon Coin use...
#####################################################

STRATUM_DIR=/var/stratum
#!/usr/bin/env bash

'""''"${coinsymbollower}"''""'="screen -dmS '""''"${coinsymbollower}"''""' bash $STRATUM_DIR/run.sh '""''"${coinsymbollower}"''""'.'""''"${coinalgo}"''""'"
'""''"${coinsymbollower}"''""'stop="'screen -X -S ${coinsymbollower} quit'"

startstop_'""''"${coinsymbollower}"''""'() {
    cmd=$1
    case $cmd in
        stop) $'""''"${coinsymbollower}"''""'stop ;;
        start) $'""''"${coinsymbollower}"''""' ;;
        restart)
            $'""''"${coinsymbollower}"''""'stop
            sleep 1
            $'""''"${coinsymbollower}"''""'
            ;;
    esac
}

case "$1" in
    start|stop|restart) cmd=$1 ;;
    *)
        shift
        servicenames=${@-servicenames}
        echo "usage: $0 [start|stop|restart] algo"
        exit 1
esac


shift

for name; do
    case "$name" in
    '""''"${coinsymbollower}"''""') startstop_'""''"${coinsymbollower}"''""' $cmd ;;
    *) startstop_service $cmd $name ;;
    esac
done ' | sudo -E tee /var/stratum/config/stratum.${coinsymbollower} >/dev/null 2>&1
sudo chmod +x /var/stratum/config/stratum.${coinsymbollower}

sudo cp -r stratum.${coinsymbollower} /usr/bin
sudo ufw allow $coinport
echo
echo "Adding stratum.${coinsymbollower} to crontab for autostart at system boot."
(crontab -l 2>/dev/null; echo "@reboot sleep 10 && bash stratum.${coinsymbollower} start ${coinsymbollower}") | crontab -
echo
echo -e "$YELLOW Starting your new stratum...$COL_RESET"
bash stratum.${coinsymbollower} start ${coinsymbollower}
echo -e "$YELLOW Your new stratum is$GREEN started...$YELLOW Do NOT run the start command manually...$COL_RESET"
echo
echo -e "$YELLOW To use your new stratum type,$BLUE stratum.${coinsymbollower} start|stop|restart ${coinsymbollower} $COL_RESET"
echo
echo -e "$YELLOW To see the stratum screen type,$MAGENTA screen -r ${coinsymbollower} $COL_RESET"
echo
echo -e "$YELLOW The assigned dedicated port for this coins stratum is :$YELLOW $coinport $COL_RESET"
echo
echo -e "$YELLOW Make sure to add this to the Dedicated Port section in your YiiMP admin panel! $COL_RESET"

cd ~
exit 0
