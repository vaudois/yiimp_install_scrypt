#!/bin/bash
################################################################################
#
# Program:
#   Install needed packages to compile cryptocurrency on Ubuntu 20.04/22.04
#
################################################################################

function package_compile_crypto
{
    # Activer le dépôt universe si nécessaire
    echo " >--> Ensuring universe repository is enabled..."
    sudo add-apt-repository universe -y > /dev/null 2>&1
	simple_hide_output "Updating apt..." apt -y update
	simple_hide_output "Upgrading apt..." apt -y upgrade

    # Paquets de base pour la compilation
    apt_install build-essential libc6-dev libtool gettext bsdmainutils git cmake autotools-dev automake pkg-config libzmq3-dev
    apt_install libssl-dev libevent-dev libseccomp-dev libcap-dev libminiupnpc-dev libboost-all-dev zlib1g-dev
    apt_install libgmp-dev libmariadb-dev libkrb5-dev gnutls-dev screen

	echo -e "$GREEN Done...$COL_RESET"
 	sleep 3
 	echo -e "$YELLOW => Installing Package to compile crypto currency$YELLOW step 2 $COL_RESET"
 	sleep 3
	
    # Berkeley DB pour la compatibilité avec les portefeuilles de cryptomonnaies
    apt_install libdb5.3-dev libdb5.3++-dev

    # Paquets pour l'interface graphique (Qt)
    apt_install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
    apt_install libcanberra-gtk-module libqrencode-dev

	echo -e "$GREEN Done...$COL_RESET"
 	sleep 3
 	echo -e "$YELLOW => Installing Package to compile crypto currency$YELLOW step 3 $COL_RESET"
 	sleep 3

    # Dépendances réseau et autres
    apt_install libunbound-dev libsodium-dev libunwind-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev
    apt_install libpgm-dev libhidapi-dev libusb-1.0-0-dev libudev-dev
    apt_install libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev
    apt_install libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev
    apt_install libboost-system-dev libboost-thread-dev
    apt_install libmariadb-dev librtmp-dev libssh2-1-dev libldap2-dev  # Remplacé default-libmysqlclient-dev par libmariadb-dev
    apt_install libbrotli-dev libssh-dev libnghttp2-dev libpsl-dev
    apt_install python3 ccache doxygen graphviz  # Retiré libmysqlclient-dev
	apt_install libzstd-dev

	echo -e "$GREEN Done...$COL_RESET"
 	sleep 3
 	echo -e "$YELLOW => Installing Package to compile crypto currency$YELLOW step 4 $COL_RESET"
 	sleep 3

    # Paquets spécifiques à Ubuntu 20.04 ou 22.04
    if [[ "$DISTRO" == "20" ]]; then
        apt_install libcurl4-gnutls-dev libidn11-dev libgcc-10-dev
    elif [[ "$DISTRO" == "22" ]]; then
        apt_install libcurl4-openssl-dev libidn2-dev libgcc-11-dev
    fi

	echo -e "$GREEN Done...$COL_RESET"
 	sleep 3
  
	clear
	term_art_server
 	echo -e "$YELLOW => Modify DB for Stratum $COL_RESET"
 	sleep 3

	# Setup MariaDB symbolic links
	if [ -f /usr/bin/mariadb_config ] && [ ! -f /usr/bin/mysql_config ]; then
	    echo -e "${CYAN}Processing: Creating symbolic link for mariadb_config to mysql_config...${COL_RESET}"
	    sudo ln -sf /usr/bin/mariadb_config /usr/bin/mysql_config
	fi
	if [ -d /usr/include/mariadb ] && [ ! -d /usr/include/mysql ]; then
	    echo -e "${CYAN}Processing: Creating symbolic link for /usr/include/mysql to /usr/include/mariadb...${COL_RESET}"
	    sudo ln -sf /usr/include/mariadb /usr/include/mysql
	fi
	
	# Create symbolic link for libmysqlclient dynamically
	LIB_PATH=$(find /usr/lib -type f \( -name 'libmysqlclient.so.*' -o -name 'libmariadb.so.*' \) -print -quit 2>/dev/null)
	if [ -n "$LIB_PATH" ]; then
	    echo -e "${CYAN}Processing: Creating symbolic link for libmysqlclient...${COL_RESET}"
	    LIB_DIR=$(dirname "$LIB_PATH")
	    sudo ln -sf "$LIB_PATH" "$LIB_DIR/libmysqlclient.so"
	    echo -e "${CYAN}Processing: Updating linker cache...${COL_RESET}"
	    sudo ldconfig
	else
	    echo -e "${RED}Error: No suitable MariaDB/MySQL client library found${COL_RESET}"
	    log_message "ERROR: No suitable MariaDB/MySQL client library found"
	    exit 1
	fi
 
    # Vérifier les paquets essentiels (non bloquant)
    for pkg in build-essential libc6-dev libgcc-11-dev; do
        if ! dpkg -l | grep -q $pkg; then
            echo -e "$RED Warning: Failed to install $pkg, continuing...$COL_RESET"
        fi
    done
}
