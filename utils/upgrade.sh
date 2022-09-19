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
if [[ ! -e '$STORAGE_ROOT/coin_builder/temp_coin_builds' ]]; then
sudo mkdir -p $HOME/utils/daemon_builder/temp_coin_builds
else
echo "temp_coin_builds already exists.... Skipping"
fi

# Just double checking folder permissions
sudo setfacl -m u:$USER:rwx $HOME/utils/daemon_builder/temp_coin_builds

cd $HOME/utils/daemon_builder/temp_coin_builds

# Kill the old coin and get the github info
read -r -e -p "Enter the name of the coin : " coin
read -r -e -p "Paste the github link for the coin : " git_hub
read -r -e -p "Do you need to use a specific github branch of the coin (y/n) : " branch_git_hub
if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
read -r -e -p "Please enter the branch name exactly as in github, i.e. v2.5.1  : " branch_git_hub_ver
fi
read -r -e -p "Enter the coind name as it is in yiimp, example bitcoind : " pkillcoin

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
else
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
make -j$(nproc)
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

clear

# LS the SRC dir to have user input bitcoind and bitcoin-cli names
cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/
find . -maxdepth 1 -type f \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
read -r -e -p "Please enter the coind name from the directory above, example bitcoind :" coind
read -r -e -p "Is there a coin-cli, example bitcoin-cli [y/N] :" ifcoincli

if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
read -r -e -p "Please enter the coin-cli name :" coincli
fi

clear

# Strip and copy to /usr/bin
sudo pkill -9 ${pkillcoin}
sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin
if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli}
sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
fi

# Have user verify con.conf file and start coin
echo "I am now going to open nano, please verify if there any changes that are needed such as adding or removing addnodes."
read -n 1 -s -r -p "Press any key to continue"
sudo nano $HOME/wallets/."${coind::-1}"/${coind::-1}.conf
clear
cd $HOME/utils/daemon_builder
echo "Starting ${coind::-1}"
"${coind}" -datadir=$HOME/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile -reindex

# If we made it this far everything built fine removing last coin.conf and build directory
sudo rm -r $HOME/utils/daemon_builder/temp_coin_builds/.lastcoin.conf
sudo rm -r $HOME/utils/daemon_builder/temp_coin_builds/${coindir}
sudo rm -r $HOME/utils/daemon_builder/.my.cnf


clear
echo "Upgrade of ${coind::-1} is completed and running. The blockchain is being reindexed, it could be several minutes before you can connect to your coin."
echo Type daemonbuilder at anytime to install a new coin!
