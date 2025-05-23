#!/bin/bash
########################################################
# Modified by Vaudois for crypto use...
# Updated for Ubuntu 22.04 compatibility with PHP 8.3
# Changes:
# - Added support for DISTRO=22 with PHP 8.3
# - Improved error handling and logging
# - Maintained compatibility with Ubuntu 20.04 (PHP 8.2)
########################################################

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

# Log file for debugging
LOG_FILE="/var/log/yiimp_install.log"

# Function to log messages
function log_message {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null
}

# Spinner amélioré
function spinner {
    local pid=$1
    local message=${2:-"Processing..."}
    local delay=${3:-0.1}
    local spinstr=${4:-'⠁⠉⠙⠚⠒⠂⠂⠒⠲⢲⢳⢱⢹⢸⢸⢹⢱⢣⢣⢣⢣⢇⢇⢇⢇⢏⢏⢏⢏⢎⢎⢎⢎⢆⢆⢆⢆⢂'}
    local colors=("$YELLOW" "$GREEN" "$CYAN" "$MAGENTA" "$BLUE")
    local color_idx=0
    local i=0
    tput civis
    while kill -0 "$pid" 2>/dev/null; do
        local color=${colors[$color_idx]}
        printf "\r%s [%s%s%s]" "$message" "$color" "${spinstr:$i:1}" "$COL_RESET"
        ((i = (i + 1) % ${#spinstr}))
        ((color_idx = (color_idx + 1) % ${#colors}))
        sleep "$delay"
    done
    wait "$pid"
    local exit_code=$?
    tput cnorm
    printf "\r%-*s\r" "${#message + ${#spinstr} + 10}" ""
    return $exit_code
}

# Hide_output amélioré
function hide_output {
    local message=${1:-"Processing command..."}
    shift
    local output_file
    local exit_code

    output_file=$(mktemp) || {
        echo -e "${RED}Error: Failed to create temporary file${COL_RESET}"
        log_message "Failed to create temporary file for command: $@"
        exit 1
    }

    log_message "Running command: $@"
    "$@" &> "$output_file" &
    local pid=$!
    spinner "$pid" "$message" || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo
        echo -e "${RED}FAILED: $@${COL_RESET}"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        cat "$output_file"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        log_message "Command failed: $@"
        rm -f "$output_file"
        exit $exit_code
    fi

    log_message "Command succeeded: $@"
    rm -f "$output_file"
}

function apt_get_quiet {
    local message="Installing packages..."
    DEBIAN_FRONTEND=noninteractive hide_output "$message" sudo apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

function apt_install {
    PACKAGES=$@
    log_message "Installing packages: $PACKAGES"
    apt_get_quiet install $PACKAGES
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install packages: $PACKAGES${COL_RESET}"
        log_message "Failed to install packages: $PACKAGES"
        exit 1
    fi
    log_message "Successfully installed packages: $PACKAGES"
}

function ufw_allow {
    if [ -z "$DISABLE_FIREWALL" ]; then
        log_message "Allowing port $1 in UFW"
        hide_output "Allowing port $1 in UFW..." sudo ufw allow "$1"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to allow port $1 in UFW${COL_RESET}"
            log_message "Failed to allow port $1 in UFW"
            exit 1
        fi
        log_message "Port $1 allowed in UFW"
    fi
}

function restart_service {
    log_message "Restarting service $1"
    hide_output "Restarting $1..." sudo service "$1" restart
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to restart service $1${COL_RESET}"
        log_message "Failed to restart service $1"
        exit 1
    fi
    log_message "Service $1 restarted"
}

## Dialog Functions ##
function message_box {
    dialog --title "$1" --msgbox "$2" 0 0
    log_message "Displayed message box: $1"
}

function input_box {
    declare -n result=$4
    declare -n result_code=$4_EXITCODE
    result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
    result_code=$?
    log_message "Input box '$1' result: $result (exit code: $result_code)"
}

function input_menu {
    declare -n result=$4
    declare -n result_code=$4_EXITCODE
    local IFS=^$'\n'
    result=$(dialog --stdout --title "$1" --menu "$2" 0 0 0 $3)
    result_code=$?
    log_message "Input menu '$1' result: $result (exit code: $result_code)"
}

function get_publicip_from_web_service {
    log_message "Fetching public IP (IPv$1)"
    local ip=$(curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to fetch public IP${COL_RESET}"
        log_message "Failed to fetch public IP"
        exit 1
    fi
    log_message "Public IP: $ip"
    echo "$ip"
}

function get_default_privateip {
    target=8.8.8.8
    if [ "$1" == "6" ]; then target=2001:4860:4860::8888; fi
    log_message "Fetching default private IP (IPv$1)"
    route=$(ip -$1 -o route get $target | grep -v unreachable)
    if [ -z "$route" ]; then
        echo -e "${RED}Failed to fetch route for $target${COL_RESET}"
        log_message "Failed to fetch route for $target"
        exit 1
    fi
    address=$(echo $route | sed "s/.* src \([^ ]*\).*/\1/")
    if [[ "$1" == "6" && $address == fe80:* ]]; then
        interface=$(echo $route | sed "s/.* dev \([^ ]*\).*/\1/")
        address=$address%$interface
    fi
    log_message "Default private IP: $address"
    echo $address
}

# Terminal art start screen.
function term_art_server {
    if [[ "${DISTRO}" == "22" ]]; then
        PHPINSTALL=8.3
    elif [[ "${DISTRO}" == "20" ]]; then
        PHPINSTALL=8.2
    else
        PHPINSTALL=7.3
    fi
    clear
    echo
    startlogo
    echo -e "$YELLOW  Welcome to the Yiimp Installer Script , Fork By Vaudois!				$COL_RESET"
    echo -e "$GREEN  Version:$COL_RESET$MAGENTA ${TAG}$GREEN Installation on Distro ${MAGENTA}${DISTRO}	$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    echo -e "$YELLOW  This script will install all the dependencies and will install Yiimp.			$COL_RESET"
    echo -e "$YELLOW  It will also install a MySQL database and a Web server.				$COL_RESET"
    echo -e "$YELLOW  MariaDB is used for the database.							$COL_RESET"
    echo -e "$YELLOW  Nginx is used for the Web server, PHP$MAGENTA ${PHPINSTALL}$YELLOW is also installed.	$COL_RESET"
    echo -e "$CYAN  ------------------------------------------------------------------------------------	$COL_RESET"
    echo
    log_message "Displayed term_art_server for DISTRO=$DISTRO, PHP=$PHPINSTALL"
}

function install_end_message {
    clear
    echo
    figlet -f slant -w 100 " Complete!"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$GREEN  |    Version: $MAGENTA ${TAG}    $GREEN|							$COL_RESET"
    echo -e "$YELLOW   Yiimp Installer Script Fork By Vaudois							$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$YELLOW   Your mysql information (login/Password) is saved in:$RED ~/.my.cnf				$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$YELLOW   Your pool  at :$CYAN http://"$server_name"							$COL_RESET"
    echo -e "$YELLOW   Admin area at :$CYAN http://"$server_name"/site/$admin_panel					$COL_RESET"
    echo -e "$YELLOW   phpMyAdmin at :$CYAN http://"$server_name"/phpmyadmin					$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$YELLOW   If you want change $RED$admin_panel								$COL_RESET"
    echo -e "$YELLOW   Edit this: $RED/var/web/yaamp/modules/site/SiteController.php				$COL_RESET"
    echo -e "$YELLOW   On line 11 => change it to your preference.							$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$YELLOW   Please make sure to change your$RED public keys and your wallet addresses in:		$COL_RESET"
    echo -e "$RED   	/var/web/serverconfig.php								$COL_RESET"
    echo -e "$YELLOW   Your change private keys in the$RED /etc/yiimp/keys.php$YELLOW file.	$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$RED   How to Build new Coin & use Addport & crons commands : main, loop2, blocks			$COL_RESET"
    echo -e "$GREEN	To build a new coin :$MAGENTA	coinbuild							$COL_RESET"
    echo -e "$GREEN	To added stratum to coin and dedicated port :$MAGENTA	addport					$COL_RESET"
    echo -e "$GREEN	To Crons commands :$MAGENTA	motd								$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    donations
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo -e "$YELLOW 	|  YOU MUST$RED REBOOT$YELLOW NOW  TO FINALIZE INSTALLATION Thanks you!  |		$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------		$COL_RESET"
    echo
    log_message "Installation completed, displayed end message"
    cd ~
}

function startlogo {
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    echo "																							"
    echo "  ░██████╗███████╗██████╗░██╗░░░██╗███████╗██████╗░  ██╗░░░██╗██╗██╗███╗░░░███╗██████╗░	"
    echo "  ██╔════╝██╔════╝██╔══██╗██║░░░██║██╔════╝██╔══██╗  ╚██╗░██╔╝██║██║████╗░████║██╔══██╗	"
    echo "  ╚█████╗░█████╗░░██████╔╝╚██╗░██╔╝█████╗░░██████╔╝  ░╚████╔╝░██║██║██╔████╔██║██████╔╝	"
    echo "  ░╚═══██╗██╔══╝░░██╔══██╗░╚████╔╝░██╔══╝░░██╔══██╗  ░░╚██╔╝░░██║██║██║╚██╔╝██║██╔═══╝░	"
    echo "  ██████╔╝███████╗██║░░██║░░╚██╔╝░░███████╗██║░░██║  ░░░██║░░░██║██║██║░╚═╝░██║██║░░░░░	"
    echo "  ╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ░░░╚═╝░░░╚═╝╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░	"
    echo "																							"
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    log_message "Displayed start logo"
}

function donations {
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    echo -e "$GREEN	Donations are welcome at wallets below:							$COL_RESET"
    echo -e "$YELLOW  BTC:$COL_RESET $MAGENTA btcdons	$COL_RESET"
    echo -e "$YELLOW  LTC:$COL_RESET $MAGENTA ltcdons	$COL_RESET"
    echo -e "$YELLOW  ETH:$COL_RESET $MAGENTA ethdons	$COL_RESET"
    echo -e "$YELLOW  BCH:$COL_RESET $MAGENTA bchdons	$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    log_message "Displayed donation addresses"
}
