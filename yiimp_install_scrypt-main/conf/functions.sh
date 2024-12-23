	#!/bin/bash
#####################################################
# Modified by Vaudois for crypto use...
# Further modified to work with Ubuntu 20.04 and 22.04 without Apache
#####################################################
 
absolutepath=absolutepathserver
installtoserver=installpath
daemonname=daemonnameserver
 
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"
 
 
function spinner {
         local pid=$!
         local delay=0.75
         local spinstr='|/-\'
         while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
                 local temp=${spinstr#?}
                 printf " [%c]  " "$spinstr"
                 local spinstr=$temp${spinstr%"$temp"}
                 sleep $delay
                 printf "\b\b\b\b\b\b"
         done
         printf "    \b\b\b\b"
}
 
 
function hide_output {
        OUTPUT=$(mktemp)
        $@ &> $OUTPUT & spinner
        E=$?
        if [ $E != 0 ]; then
        echo
        echo FAILED: $@
        echo -----------------------------------------
        cat $OUTPUT
        echo -----------------------------------------
        exit $E
        fi
 
        rm -f $OUTPUT
}
 
 
function apt_get_quiet {
        DEBIAN_FRONTEND=noninteractive hide_output sudo apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}
 
 
function apt_install {
        PACKAGES=$@
        apt_get_quiet install $PACKAGES
}
 
 
function ufw_allow {
        if [ -z "$DISABLE_FIREWALL" ]; then
        sudo ufw allow $1 > /dev/null;
        fi
}
 
function restart_service {
        hide_output sudo systemctl restart $1
}
 
## Dialog Functions ##
function message_box {
        dialog --title "$1" --msgbox "$2" 0 0
}
 
function input_box {
        # input_box "title" "prompt" "defaultvalue" VARIABLE
        # The user's input will be stored in the variable VARIABLE.
        # The exit code from dialog will be stored in VARIABLE_EXITCODE.
        declare -n result=$4
        declare -n result_code=$4_EXITCODE
        result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
        result_code=$?
}
 
function input_menu {
        # input_menu "title" "prompt" "tag item tag item" VARIABLE
        # The user's input will be stored in the variable VARIABLE.
        # The exit code from dialog will be stored in VARIABLE_EXITCODE.
        declare -n result=$4
        declare -n result_code=$4_EXITCODE
        local IFS=^$'\n'
        result=$(dialog --stdout --title "$1" --menu "$2" 0 0 0 $3)
        result_code=$?
}
 
function get_publicip_from_web_service {
        # This seems to be the most reliable way to determine the
        # machine's public IP address: asking a very nice web API
        # for how they see us. Thanks go out to icanhazip.com.
        # See: https://major.io/icanhazip-com-faq/
        #
        # Pass '4' or '6' as an argument to this function to specify
        # what type of address to get (IPv4, IPv6).
        curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null
}
 
function get_default_privateip {
        # Return the IP address of the network interface connected
        # to the Internet.
        #
        # Pass '4' or '6' as an argument to this function to specify
        # what type of address to get (IPv4, IPv6).
        #
        # We used to use `hostname -I` and then filter for either
        # IPv4 or IPv6 addresses. However if there are multiple
        # network interfaces on the machine, not all may be for
        # reaching the Internet.
        #
        # Instead use `ip route get` which asks the kernel to use
        # the system's routes to select which interface would be
        # used to reach a public address. We'll use 8.8.8.8 as
        # the destination. It happens to be Google Public DNS, but
        # no connection is made. We're just seeing how the box
        # would connect to it. There many be multiple IP addresses
        # assigned to an interface. `ip route get` reports the
        # preferred. That's good enough for us. See issue #121.
        #
        # With IPv6, the best route may be via an interface that
        # only has a link-local address (fe80::*). These addresses
        # are only unique to an interface and so need an explicit
        # interface specification in order to use them with bind().
        # In these cases, we append "%interface" to the address.
        # See the Notes section in the man page for getaddrinfo and
        # https://discourse.mailinabox.email/t/update-broke-mailinabox/34/9.
        #
        # Also see ae67409603c49b7fa73c227449264ddd10aae6a9 and
        # issue #3 for why/how we originally added IPv6.
 
        target=8.8.8.8
 
        # For the IPv6 route, use the corresponding IPv6 address
        # of Google Public DNS. Again, it doesn't matter so long
        # as it's an address on the public Internet.
        if [ "$1" == "6" ]; then target=2001:4860:4860::8888; fi
 
        # Get the route information.
        route=$(ip -$1 -o route get $target | grep -v unreachable)
 
        # Parse the address out of the route information.
        address=$(echo $route | sed "s/.* src \([^ ]*\).*/\1/")
 
        if [[ "$1" == "6" && $address == fe80:* ]]; then
        # For IPv6 link-local addresses, parse the interface out
        # of the route information and append it with a '%'.
        interface=$(echo $route | sed "s/.* dev \([^ ]*\).*/\1/")
        address=$address%$interface
        fi
 
        echo $address
}
 
 
# terminal art start screen.
function term_art_server
{
    # Detect Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs)
    if [[ "${UBUNTU_VERSION}" == "20.04" ]]; then
         PHPINSTALL=php7.4
       elif [[ "${UBUNTU_VERSION}" == "22.04" ]]; then
             PHPINSTALL=php8.2
           else
        echo "Unsupported Ubuntu version. This script is designed for Ubuntu 20.04 or 22.04."
        exit 1
    fi
    clear
    echo
    startlogo
    echo -e "$YELLOW  Welcome to the Yiimp Installer Script , Fork By Vaudois!             $COL_RESET"
    echo -e "$GREEN  Version:$COL_RESET$MAGENTA ${TAG}$GREEN Installation on Ubuntu ${MAGENTA}${UBUNTU_VERSION}  $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------  $COL_RESET"
    echo -e "$YELLOW  This script will install all the dependencies and will install Yiimp.            $COL_RESET"
    echo -e "$YELLOW  It will also install a MySQL database and a Web server.              $COL_RESET"
    echo -e "$YELLOW  MariaDB is used for the database.                            $COL_RESET"
    echo -e "$YELLOW  Nginx is used for the Web server, PHP$MAGENTA ${PHPINSTALL}$YELLOW is also installed. $COL_RESET"
    echo -e "$CYAN  ------------------------------------------------------------------------------------   $COL_RESET"
    echo
}
 
function install_end_message
{
    clear
    echo
    figlet -f slant -w 100 " Complete!"
 
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$GREEN  |    Version: $MAGENTA ${TAG}    $GREEN|                           $COL_RESET"
    echo -e "$YELLOW   Yiimp Installer Script Fork By Vaudois                          $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$YELLOW   Your mysql information (login/Password) is saved in:$RED ~/.my.cnf             $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$YELLOW   Your pool  at :$CYAN http://"$server_name"                            $COL_RESET"
    echo -e "$YELLOW   Admin area at :$CYAN http://"$server_name"/site/$admin_panel                 $COL_RESET"
    echo -e "$YELLOW   phpMyAdmin at :$CYAN http://"$server_name"/phpmyadmin                 $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$YELLOW   If you want change $RED$admin_panel                               $COL_RESET"
    echo -e "$YELLOW   Edit this: $RED/var/web/yaamp/modules/site/SiteController.php              $COL_RESET"
    echo -e "$YELLOW   On line 11 => change it to your preference.                         $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$YELLOW   Please make sure to change your$RED public keys and your wallet addresses in:      $COL_RESET"
    echo -e "$RED      /var/web/serverconfig.php                               $COL_RESET"
    echo -e "$YELLOW   Your change private keys in the$RED /etc/yiimp/keys.php$YELLOW file.  $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$RED   How to Build new Coin & use Addport & crons commands : main, loop2, blocks         $COL_RESET"
    echo -e "$GREEN    To build a new coin :$MAGENTA  coinbuild                           $COL_RESET"
    echo -e "$GREEN    To added stratum to coin and dedicated port :$MAGENTA  addport                 $COL_RESET"
    echo -e "$GREEN    To Crons commands :$MAGENTA    motd                                $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    donations
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo -e "$YELLOW   |  YOU MUST$RED REBOOT$YELLOW NOW  TO FINALIZE INSTALLATION Thanks you!  |        $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------      $COL_RESET"
    echo
    cd ~
}
 
function startlogo
{
    echo -e "$CYAN  -------------------------------------------------------------------------------------  $COL_RESET"
    echo "                                                                                          "
    echo "  ░██████╗███████╗██████╗░██╗░░░██╗███████╗██████╗░  ██╗░░░██╗██╗██╗███╗░░░███╗██████╗░   "
    echo "  ██╔════╝██╔════╝██╔══██╗██║░░░██║██╔════╝██╔══██╗  ╚██╗░██╔╝██║██║████╗░████║██╔══██╗   "
    echo "  ╚█████╗░█████╗░░██████╔╝╚██╗░██╔╝█████╗░░██████╔╝  ░╚████╔╝░██║██║██╔████╔██║██████╔╝   "
    echo "  ░╚═══██╗██╔══╝░░██╔══██╗░╚████╔╝░██╔══╝░░██╔══██╗  ░░╚██╔╝░░██║██║██║╚██╔╝██║██╔═══╝░   "
    echo "  ██████╔╝███████╗██║░░██║░░╚██╔╝░░███████╗██║░░██║  ░░░██║░░░██║██║██║░╚═╝░██║██║░░░░░   "
    echo "  ╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ░░░╚═╝░░░╚═╝╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░   "
    echo "                                                                                          "
    echo -e "$CYAN  -------------------------------------------------------------------------------------  $COL_RESET"
}
 
function donations
{
    echo -e "$CYAN  -------------------------------------------------------------------------------------  $COL_RESET"
    echo -e "$GREEN    Donations are welcome at wallets below:                         $COL_RESET"
    echo -e "$YELLOW  BTC:$COL_RESET $MAGENTA btcdons    $COL_RESET"
    echo -e "$YELLOW  LTC:$COL_RESET $MAGENTA ltcdons    $COL_RESET"
    echo -e "$YELLOW  ETH:$COL_RESET $MAGENTA ethdons    $COL_RESET"
    echo -e "$YELLOW  BCH:$COL_RESET $MAGENTA bchdons    $COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------  $COL_RESET"
}