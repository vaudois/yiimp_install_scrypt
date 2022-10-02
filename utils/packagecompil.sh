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

function package_compile_coin
{
	sudo mkdir -p ${absolutepath}/tmp
	
	sleep 3
	echo
	echo -e "$YELLOW Building Berkeley 4.8, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/tmp
	sudo mkdir -p ${absolutepath}/${installtoserver}/berkeley/db4/
	hide_output sudo wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
	hide_output sudo tar -xzvf db-4.8.30.NC.tar.gz
	cd db-4.8.30.NC/build_unix/
	hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${absolutepath}/${installtoserver}/berkeley/db4/
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r db-4.8.30.NC.tar.gz db-4.8.30.NC
	echo -e "$GREEN Berkeley 4.8 Completed...$COL_RESET"

	echo
	echo -e "$YELLOW Building Berkeley 5.1, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/tmp
	sudo mkdir -p ${absolutepath}/${installtoserver}/berkeley/db5/
	hide_output sudo wget 'http://download.oracle.com/berkeley-db/db-5.1.29.tar.gz'
	hide_output sudo tar -xzvf db-5.1.29.tar.gz
	cd db-5.1.29/build_unix/
	hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${absolutepath}/${installtoserver}/berkeley/db5/
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r db-5.1.29.tar.gz db-5.1.29
	echo -e "$GREEN Berkeley 5.1 Completed...$COL_RESET"

	echo
	echo -e "$YELLOW Building Berkeley 5.3, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/tmp
	sudo mkdir -p ${absolutepath}/${installtoserver}/berkeley/db5.3/
	hide_output sudo wget 'http://anduin.linuxfromscratch.org/BLFS/bdb/db-5.3.28.tar.gz'
	hide_output sudo tar -xzvf db-5.3.28.tar.gz
	cd db-5.3.28/build_unix/
	hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${absolutepath}/${installtoserver}/berkeley/db5.3/
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r db-5.3.28.tar.gz db-5.3.28
	echo -e "$GREEN Berkeley 5.3 Completed...$COL_RESET"

	echo
	echo -e "$YELLOW Building Berkeley 6.2, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/tmp
	sudo mkdir -p ${absolutepath}/${installtoserver}/berkeley/db6.2/
	hide_output sudo wget 'http://download.oracle.com/berkeley-db/db-6.2.23.tar.gz'
	hide_output sudo tar -xzvf db-6.2.23.tar.gz
	cd db-6.2.23/build_unix/
	hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${absolutepath}/${installtoserver}/berkeley/db6.2/
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r db-6.2.23.tar.gz db-6.2.23
	echo -e "$GREEN Berkeley 6.2 Completed...$COL_RESET"

	echo
	echo -e "$YELLOW Building OpenSSL 1.0.2g, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/tmp
	hide_output sudo wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2g.tar.gz --no-check-certificate
	hide_output sudo tar -xf openssl-1.0.2g.tar.gz
	cd openssl-1.0.2g
	hide_output sudo ./config --prefix=${absolutepath}/${installtoserver}/openssl --openssldir=${absolutepath}/${installtoserver}/openssl shared zlib
	hide_output sudo make
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r openssl-1.0.2g.tar.gz openssl-1.0.2g
	echo -e "$GREEN OpenSSL 1.0.2g Completed...$COL_RESET"

	echo
	echo -e "$YELLOW Building bls-signatures, this may take several minutes...$COL_RESET"
	echo
	sleep 3
	cd ${absolutepath}/yiimp_install_scrypt/conf/package
	hide_output sudo cp -r bls-signatures-20181101.zip ${absolutepath}/tmp
	cd ${absolutepath}/tmp
	hide_output sudo unzip bls-signatures-20181101.zip
	cd bls-signatures-20181101
	hide_output sudo cmake .
	hide_output sudo make install
	cd ${absolutepath}/tmp
	sudo rm -r bls-signatures-20181101.zip bls-signatures-20181101
	echo -e "$GREEN bls-signatures Completed...$COL_RESET"
	
	sleep 3
	sudo rm -rf ${absolutepath}/tmp
	echo
	echo
	echo -e "$GREEN Done...$COL_RESET"
}

function package_daemonbuilder
{
	# Install Daemonbuilder
	echo
	echo
	echo -e "$CYAN => Install DaemonBuilder Coin. $COL_RESET"
	echo

	echo -e "$CYAN => Installing DaemonBuilder $COL_RESET"
	
	cd ~
	cd ${absolutepath}/yiimp_install_scrypt/utils
	sudo mkdir -p ${absolutepath}/${installtoserver}/daemon_builder/

	hide_output sudo cp -r start.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r menu.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r menu1.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r menu2.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r menu3.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r menu4.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r source.sh ${absolutepath}/${installtoserver}/daemon_builder
	hide_output sudo cp -r info.sh ${absolutepath}/${installtoserver}/conf
	sleep 3
	
	echo '#!/usr/bin/env bash
	source /etc/functions.sh # load our functions
	cd '"${absolutepath}"'/'"${installtoserver}"'/daemon_builder
	bash start.sh
	cd ~' | sudo -E tee /usr/bin/${daemonname} >/dev/null 2>&1
	sudo chmod +x /usr/bin/${daemonname}

	sleep 3
}
