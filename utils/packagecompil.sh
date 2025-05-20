#!/bin/bash
################################################################################
#
# Program:
#   Install needed packages to compile cryptocurrency on Ubuntu 20.04/22.04
#
################################################################################

function package_compile_crypto
{
    echo " >--> Installing needed packages to compile cryptocurrency"
    sleep 3

    # Mise à jour du système
    echo " >--> Updating system for Ubuntu 20.04/22.04..."
    sudo apt -y update && sudo apt -y upgrade -qq > /dev/null 2>&1
    sudo apt -y autoremove -qq > /dev/null 2>&1

    # Paquets de base pour la compilation
    apt_install build-essential libtool gettext bsdmainutils git cmake autotools-dev automake pkg-config libzmq3-dev
    apt_install libssl-dev libevent-dev libseccomp-dev libcap-dev libminiupnpc-dev libboost-all-dev zlib1g-dev
    apt_install libgmp-dev libmariadb-dev libkrb5-dev gnutls-dev screen

    # Berkeley DB pour la compatibilité avec les portefeuilles de cryptomonnaies
    apt_install libdb5.3-dev libdb5.3++-dev

    # Paquets pour l'interface graphique (Qt)
    apt_install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
    apt_install libcanberra-gtk-module libqrencode-dev

    # Dépendances réseau et autres
    apt_install libunbound-dev libsodium-dev libunwind-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev
    apt_install libpgm-dev libhidapi-dev libusb-1.0-0-dev libudev-dev
    apt_install libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev
    apt_install libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev
    apt_install libboost-system-dev libboost-thread-dev
    apt_install default-libmysqlclient-dev librtmp-dev libssh2-1-dev libldap2-dev
    apt_install libbrotli-dev libssh-dev libnghttp2-dev libpsl-dev
    apt_install python3 ccache doxygen graphviz

    # Paquets spécifiques à Ubuntu 20.04 ou 22.04
    if [[ "$DISTRO" == "20" ]]; then
        apt_install libcurl4-gnutls-dev libidn11-dev
    elif [[ "$DISTRO" == "22" ]]; then
        apt_install libcurl4-openssl-dev libidn2-dev
    fi

    echo -e "$GREEN Done...$COL_RESET"
}

# Fonction utilitaire pour installer les paquets
function apt_install
{
    sudo apt install -y "$@"
}

# Appel de la fonction
package_compile_crypto
