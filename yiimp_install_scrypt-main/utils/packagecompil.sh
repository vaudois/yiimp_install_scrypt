#!/bin/bash
################################################################################ 
#
# Program:
#   Install needed Package to compile crypto currency
# 
################################################################################
 
function package_compile_crypto
{
    # Installing Package to compile crypto currency
    output " >--> Installing needed Package to compile crypto currency"
    sleep 3
 
 # Add repository for Bitcoin Core PPA
    # sudo add-apt-repository ppa:luke-jr/bitcoincore -y > /dev/null 2>&1
 
    # Update package lists
    output " >--> Updating system..."
    sudo apt update -y > /dev/null 2>&1
 
    # Install common packages
    apt_install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev libboost-all-dev
    apt_install libzmq3-dev libminiupnpc-dev libnatpmp-dev libzmq5 libseccomp-dev libcap-dev
    apt_install zlib1g-dev libz-dev gettext bsdmainutils git cmake
    apt_install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
    apt_install libqrencode-dev
 
    # Install specific packages for Ubuntu 20.04 and 22.04
    if [[ "${DISTRO}" == "20" || "${DISTRO}" == "22" ]]; then
        apt_install libdb5.3-dev libdb5.3++-dev
    fi
 
    # Install additional packages
    apt_install libgmp-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev
    apt_install libpgm-dev libhidapi-dev libusb-1.0-0-dev libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev
    apt_install libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev
    apt_install default-libmysqlclient-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev
    apt_install liblbfgs-dev libbrotli-dev libssh-dev libnghttp2-dev libpsl-dev
    apt_install python3 ccache doxygen graphviz
 
    # Upgrade system
    output " >--> Upgrading system..."
    sudo apt upgrade -y > /dev/null 2>&1
}

