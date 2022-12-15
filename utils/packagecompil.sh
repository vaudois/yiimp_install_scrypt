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
    output " "
    output "Installing needed Package to compile crypto currency"
    output " "
    sleep 3

    hide_output sudo apt -y install software-properties-common build-essential
    hide_output sudo apt -y install libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev libseccomp-dev libcap-dev libminiupnpc-dev gettext
    hide_output sudo apt -y install libminiupnpc10 libzmq5
    hide_output sudo apt -y install libcanberra-gtk-module libqrencode-dev libzmq3-dev
    hide_output sudo apt -y install libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
    hide_output sudo add-apt-repository -y ppa:bitcoin/bitcoin
    hide_output sudo apt -y update
    hide_output sudo apt -y install libdb4.8-dev libdb4.8++-dev libdb5.3 libdb5.3++

	hide_output sudo apt-get -y install build-essential libzmq5 \
	libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev \
	libseccomp-dev libcap-dev libminiupnpc-dev gettext libminiupnpc10 libcanberra-gtk-module libqrencode-dev libzmq3-dev \
	libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
	hide_output sudo apt -y update && sudo apt -y upgrade

	hide_output sudo apt -y install	libgmp-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev libldns-dev libexpat1-dev \
	libpgm-dev libhidapi-dev libusb-1.0-0-dev libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev \
	libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev \
	python3 ccache doxygen graphviz default-libmysqlclient-dev libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev
}
