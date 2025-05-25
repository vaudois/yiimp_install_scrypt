#!/bin/bash
########################################################
# Modified by Vaudois for crypto use...
# Updated for Ubuntu 20/22 compatibility with PHP 8.3
# Changes:
# - Added support for DISTRO=22 with PHP 8.3
# - Improved error handling and logging
# - Maintained compatibility with Ubuntu 20.04 (PHP 8.2)
########################################################

absolutepath=/home/vaudois
installtoserver=coin-setup
daemonname=coinbuild

# Forcer le terminal et l'encodage
export TERM=xterm-256color
export LC_ALL=C.UTF-8

# Vérifier et installer ncurses-bin et dialog en silence total
function check_and_install_dependencies {
    local packages="ncurses-bin dialog"
    local missing_packages=""

    for pkg in $packages; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing_packages="$missing_packages $pkg"
    done

    if [ -n "$missing_packages" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y -qq $missing_packages >/dev/null 2>&1
        [ $? -ne 0 ] && exit 1
    fi
}

# Rafraîchir le cache sudo pour éviter l'expiration
function refresh_sudo_cache {
    sudo -n true 2>/dev/null || {
        echo -e "${RED}Error: Sudo cache expired or not available. Please re-run with sudo or configure NOPASSWD.${COL_RESET}"
        log_message "Sudo cache refresh failed"
        exit 1
    }
    log_message "Sudo cache refreshed"
}

# Vérification initiale des privilèges sudo
function check_sudo_privileges {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}Error: This script requires sudo privileges. Please run with sudo or configure NOPASSWD.${COL_RESET}"
        log_message "Sudo privileges check failed"
        exit 1
    fi
    log_message "Sudo privileges verified"
}

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

function spinner {
    local pid=$1
    local message=${2:-"Traitement..."}
    local delay=${3:-0.1} # Vitesse modérée
    local width=20 # Largeur de la barre
    local max_bars=12 # Nombre maximal de barres avant réinitialisation
    local bar_char="━" # Caractère de barre (remplacer par "-" si Unicode pose problème)
    local arrow=">" # Nouvelle flèche (remplacer par ">" si Unicode pose problème)
    local colors=("\033[38;5;26m" "\033[38;5;27m" "\033[38;5;33m" "\033[38;5;39m" "\033[38;5;45m" "\033[38;5;51m") # Dégradé bleu
    local reset="\033[0m"
    local i=0

    if [[ -t 1 && $(tput colors 2>/dev/null) -ge 8 ]]; then
        tput civis 2>/dev/null || true
        while kill -0 "$pid" 2>/dev/null; do
            local num_bars=$((i % (max_bars + 1))) # Nombre de barres (0 à max_bars)
            local color=${colors[$((i % ${#colors[@]}))]}
            # Construire la chaîne : barres + flèche
            local bars=""
            for ((j=0; j<num_bars; j++)); do
                bars="$bars$bar_char"
            done
            local current_char="$bars$arrow"
            # Calculer les espaces pour aligner à gauche dans la barre
            local spaces_before=0
            local spaces_after=$((width - ${#current_char}))
            [ $spaces_after -lt 0 ] && spaces_after=0
            local display=$(printf "%*s%s%*s" "$spaces_before" "" "$current_char" "$spaces_after" "")
            echo -ne "\r$message $color$display$reset"
            ((i++))
            sleep "$delay"
        done
        tput cnorm 2>/dev/null || true
    else
        while kill -0 "$pid" 2>/dev/null; do
            local num_bars=$((i % (max_bars + 1)))
            local bars=""
            for ((j=0; j<num_bars; j++)); do
                bars="$bars$bar_char"
            done
            local current_char="$bars$arrow"
            local spaces_before=0
            local spaces_after=$((width - ${#current_char}))
            [ $spaces_after -lt 0 ] && spaces_after=0
            local display=$(printf "%*s%s%*s" "$spaces_before" "" "$current_char" "$spaces_after" "")
            echo -ne "\r$message $display"
            ((i++))
            sleep "$delay"
        done
    fi
    wait "$pid"
    local exit_code=$?
    echo -ne "\r$(printf '%*s' "$(( ${#message} + width + 2 ))" '')\r"
    return $exit_code
}

# Hide_output amélioré pour gérer sudo
function hide_output {
    local message=${1:-"Processing command..."}
    shift
    local output_file
    local exit_code
    local cmd=("$@")

    output_file=$(mktemp) || {
        echo -e "${RED}Error: Failed to create temporary file${COL_RESET}"
        log_message "Failed to create temporary file for command: ${cmd[*]}"
        exit 1
    }

    log_message "Running command: ${cmd[*]}"
    if [[ "${cmd[0]}" == "sudo" ]]; then
        if sudo -n true 2>/dev/null; then
            shift
            sudo -n "$@" &> "$output_file" &
        else
            "${cmd[@]}" &> "$output_file" &
        fi
    else
        "${cmd[@]}" &> "$output_file" &
    fi
    local pid=$!
    spinner "$pid" "$message"
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo
        echo -e "${RED}FAILED: ${cmd[*]}${COL_RESET}"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        cat "$output_file"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        log_message "Command failed: ${cmd[*]}"
        rm -f "$output_file"
        exit $exit_code
    fi

    log_message "Command succeeded: ${cmd[*]}"
    rm -f "$output_file"
}

function simple_hide_output {
    local message="$1"
    shift
    local output_file=$(mktemp)
    log_message "Running command: $@"
    "$@" &> "$output_file" &
    local pid=$!
    spinner "$pid" "$message"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}FAILED: $@${COL_RESET}"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        cat "$output_file"
        echo -e "${RED}-----------------------------------------${COL_RESET}"
        log_message "Command failed: $@"
        rm -f "$output_file"
        exit $exit_code
    fi
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
    echo -e "$YELLOW  BTC:$COL_RESET $MAGENTA bc1qt8g9l6agk7qrzlztzuz7quwhgr3zlu4gc5qcuk	$COL_RESET"
    echo -e "$YELLOW  LTC:$COL_RESET $MAGENTA MGyth7od68xVqYnRdHQYes22fZW2b6h3aj	$COL_RESET"
    echo -e "$YELLOW  ETH:$COL_RESET $MAGENTA 0xc4e42e92ef8a196eef7cc49456c786a41d7daa01	$COL_RESET"
    echo -e "$YELLOW  BCH:$COL_RESET $MAGENTA bitcoincash:qp9ltentq3rdcwlhxtn8cc2rr49ft5zwdv7k7e04df	$COL_RESET"
    echo -e "$CYAN  -------------------------------------------------------------------------------------	$COL_RESET"
    log_message "Displayed donation addresses"
}

check_and_install_dependencies
check_sudo_privileges
