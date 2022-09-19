#!/usr/bin/env bash
#####################################################
# Created by afiniel for crypto use...
#####################################################

source /etc/functions.sh
source $HOME/utils/daemon_builder/.my.cnf
cd $HOME/utils/daemon_builder

# Set what we need
now=$(date +"%m_%d_%Y")
set -e
NPROC=$(nproc)
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds' ]]; then
sudo mkdir -p $HOME/utils/daemon_builder/temp_coin_builds
else
echo "temp_coin_builds already exists.... Skipping"
fi

# Just double checking folder permissions
sudo setfacl -m u:$USER:rwx $HOME/utils/daemon_builder/temp_coin_builds

cd $HOME/utils/daemon_builder/temp_coin_builds

# Get the github information
read -r -e -p "Enter the name of the coin : " coin
read -r -e -p "Paste the github link for the coin : " git_hub
read -r -e -p "Do you need to use a specific github branch of the coin (y/n) : " branch_git_hub
if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
read -r -e -p "Please enter the branch name exactly as in github, i.e. v2.5.1  : " branch_git_hub_ver
fi

coindir=$coin$now

# save last coin information in case coin build fails
echo '
lastcoin='"${coindir}"'
' | sudo -E tee $HOME/utils/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

# Clone the coin
if [[ ! -e $coindir ]]; then
git clone $git_hub $coindir
cd "${coindir}"
if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
  git fetch
  git checkout "$branch_git_hub_ver"
fi
else
echo "$HOME/utils/daemon_builder/temp_coin_builds/${coindir} already exists.... Skipping"
echo "If there was an error in the build use the build error options on the installer"
exit 0
fi

# Build the coin under the proper configuration
if [[ ("$autogen" == "true") ]]; then

if [[ ("$berkeley" == "4.8") ]]; then
echo "Building using Berkeley 4.8..."
basedir=$(pwd)
sh autogen.sh
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh' ]]; then
  echo "genbuild.sh not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
fi
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform' ]]; then
  echo "build_detect_platform not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
fi
./configure CPPFLAGS="-I${HOME}/utils/berkeley/db4/include -O2" LDFLAGS="-L${HOME}/utils/berkeley/db4/lib" --without-gui --disable-tests
fi
# Build the coin under berkeley 5.1
if [[ ("$berkeley" == "5.1") ]]; then
echo "Building using Berkeley 5.1..."
basedir=$(pwd)
sh autogen.sh
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh' ]]; then
  echo "genbuild.sh not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
fi
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform' ]]; then
  echo "build_detect_platform not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
fi
./configure CPPFLAGS="-I${HOME}/utils/berkeley/db5/include -O2" LDFLAGS="-L${HOME}/utils/berkeley/db5/lib" --without-gui --disable-tests
fi
# Build the coin under berkeley 5.1
if [[ ("$berkeley" == "5.3") ]]; then
echo "Building using Berkeley 5.3..."
basedir=$(pwd)
sh autogen.sh
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh' ]]; then
  echo "genbuild.sh not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
fi
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform' ]]; then
  echo "build_detect_platform not found skipping"
else
sudo chmod 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
fi
./configure CPPFLAGS="-I${HOME}/utils/berkeley/db5.3/include -O2" LDFLAGS="-L${HOME}/utils/berkeley/db5.3/lib" --without-gui --disable-tests
fi
# Build the coin under berkeley 6.2
if [[ ("$berkeley" == "6.2") ]]; then
echo "Building using Berkeley 6.2..."
basedir=$(pwd)
sh autogen.sh
find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
read -r -e -p "where is the folder that contains the BUILD.SH installation file, example xxutil :" reputil
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/${reputil}
echo $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/${reputil}
./build.sh -j$(nproc)
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/${reputil}/fetch-params.sh' ]]; then
  echo "fetch-params.sh not found skipping"
else
sh fetch-params.sh
fi
else
# make install
make -j$(nproc)
fi
else
if [[ ("$cmake" == "true") ]]; then
echo "Building using Cmake method..."
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir} && git submodule init && git submodule update
make -j$NPROC
else
echo "Building using makefile.unix method..."
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/obj' ]]; then
mkdir -p $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/obj
else
echo "Hey the developer did his job and the src/obj dir is there!"
fi
if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin' ]]; then
mkdir -p $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin
else
echo  "Wow even the /src/obj/zerocoin is there! Good job developer!"
fi
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/leveldb
sudo chmod +x build_detect_platform
sudo make clean
sudo make libleveldb.a libmemenv.a
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src
sed -i '/USE_UPNP:=0/i BDB_LIB_PATH = /home/utils/berkeley/db4/lib\nBDB_INCLUDE_PATH = /home/utils/berkeley/db4/include\nOPENSSL_LIB_PATH = /home/utils/openssl/lib\nOPENSSL_INCLUDE_PATH = /home/utils/openssl/include' makefile.unix
sed -i '/USE_UPNP:=1/i BDB_LIB_PATH = /home/utils/berkeley/db4/lib\nBDB_INCLUDE_PATH = /home/utils/berkeley/db4/include\nOPENSSL_LIB_PATH = /home/utils/openssl/lib\nOPENSSL_INCLUDE_PATH = /home/utils/openssl/include' makefile.unix
make -j$NPROC -f makefile.unix USE_UPNP=-
fi
fi

clear

# LS the SRC dir to have user input bitcoind and bitcoin-cli names
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/
find . -maxdepth 1 -type f \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
read -r -e -p "Please enter the coind name from the directory above, example bitcoind :" coind
read -r -e -p "Is there a coin-cli, example bitcoin-cli [y/N] :" ifcoincli

if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
read -r -e -p "Please enter the coin-cli name :" coincli
fi

if [[ ("$berkeley" == "6.2") ]]; then
read -r -e -p "Is there a coin-tools, example bitcoin-wallet-tools [y/N] :" ifcointools

if [[ ("$ifcointools" == "y" || "$ifcointools" == "Y") ]]; then
read -r -e -p "Please enter the coin-tools name :" cointools

sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointools}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointools} /usr/bin
fi

read -r -e -p "Is there a coin-tx, example bitcoin-tx [y/N] :" ifcointx

if [[ ("$ifcointx" == "y" || "$ifcointx" == "Y") ]]; then
read -r -e -p "Please enter the coin-tx name :" cointx

sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointx}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointx} /usr/bin
fi

read -r -e -p "Is there a coin-gtest, example bitcoin-gtest [y/N] :" ifcoingtest

if [[ ("$ifcoingtest" == "y" || "$ifcoingtest" == "Y") ]]; then
read -r -e -p "Please enter the coin-gtest name :" coingtest

sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest} /usr/bin
fi

fi

clear

# Strip and copy to /usr/bin
sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin
if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
fi

# Make the new wallet folder have user paste the coin.conf and finally start the daemon
if [[ ! -e '$HOME/wallets' ]]; then
sudo mkdir -p $HOME/wallets
fi

sudo setfacl -m u:$USER:rwx $HOME/wallets
mkdir -p $HOME/wallets/."${coind::-1}"
echo "I am now going to open nano, please copy and paste the config from yiimp in to this file."
read -n 1 -s -r -p "Press any key to continue"
sudo nano $HOME/wallets/."${coind::-1}"/${coind::-1}.conf
clear
cd $HOME/yiimpool/daemon_builder
echo "Starting ${coind::-1}"
"${coind}" -datadir=$HOME/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile

# If we made it this far everything built fine removing last coin.conf and build directory
sudo rm -r $HOME/utils/daemon_builder/temp_coin_builds/.lastcoin.conf
sudo rm -r $HOME/utils/daemon_builder/temp_coin_builds/${coindir}
sudo rm -r $HOME/utils/daemon_builder/.my.cnf


clear
echo "Installation of ${coind::-1} is completed and running."
echo Type daemonbuilder at anytime to install a new coin!
exit
