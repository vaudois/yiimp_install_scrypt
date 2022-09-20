#!/usr/bin/env bash
#####################################################
# Created by afiniel for crypto use...
#####################################################

FUNC=/etc/functionscoin.sh
if [[ ! -f "$FUNC" ]]; then
	source /etc/functions.sh
else
	source /etc/functionscoin.sh
fi

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
if [[ ("$precompiled" == "true") ]]; then
	read -r -e -p "Paste the github link coin precompiled *.tar.gz OR *.zip: " coin_precompiled
	echo
else
	read -r -e -p "Paste the github link for the coin : " git_hub
	echo
	read -r -e -p "Switch from main to develop ? [y/N] :" swithdevelop
	if [[ ("$swithdevelop" == "N" || "$swithdevelop" == "n" || "$swithdevelop" == "not" || "$swithdevelop" == "NOT" || "$swithdevelop" == "no" || "$swithdevelop" == "NO" || "$swithdevelop" == "none" || "$swithdevelop" == "NONE") ]]; then
		echo
		read -r -e -p "Do you need to use a specific github branch of the coin (y/n) : " branch_git_hub
		if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
			read -r -e -p "Please enter the branch name exactly as in github, i.e. v2.5.1  : " branch_git_hub_ver
		fi
	fi
fi

coindir=$coin$now

# save last coin information in case coin build fails
echo '
lastcoin='"${coindir}"'
' | sudo -E tee $HOME/utils/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

# Clone the coin
if [[ ! -e $coindir ]]; then
	if [[ ("$precompiled" == "true") ]]; then
		mkdir $coindir
		cd "${coindir}"
		sudo wget $coin_precompiled
	else
		git clone $git_hub $coindir
		cd "${coindir}"
	fi

	if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
	  git fetch
	  git checkout "$branch_git_hub_ver"
	fi

	if [[ ("$swithdevelop" == "y" || "$swithdevelop" == "Y" || "$swithdevelop" == "yes" || "$swithdevelop" == "Yes" || "$swithdevelop" == "YES") ]]; then
	  git checkout develop
	fi
	errorexist="false"
else
	echo "$HOME/utils/daemon_builder/temp_coin_builds/${coindir} already exists.... Skipping"
	echo "If there was an error in the build use the build error options on the installer"
	errorexist="true"
	exit 0
fi

if [[("$errorexist" == "false")]]; then
sudo chmod -R 777 $HOME/utils/daemon_builder/temp_coin_builds/${coindir}
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
  spiner_output bash build.sh -j$(nproc)
  if [[ ! -e '$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/${reputil}/fetch-params.sh' ]]; then
    echo "fetch-params.sh not found skipping"
  else
    sh fetch-params.sh
  fi
fi
if [[ ("$berkeley" != "6.2") ]]; then
# make install
make -j$(nproc)
fi
else
if [[ ("$cmake" == "true") ]]; then
  clear
  DEPENDS="$HOME/utils/daemon_builder/temp_coin_builds/${coindir}/depends"
	if [ -d "$DEPENDS" ]; then
		echo
		echo
		echo -e "$CYAN => Building using cmake with DEPENDS directory... $COL_RESET"
		echo
		sleep 3
		
		echo
		echo
		read -r -e -p "Hide LOG from to Work Coin ? [y/N] :" ifhidework
		echo
		
		# Executing make on depends directory
		echo
		echo -e "$YELLOW => executing make on depends directory... $COL_RESET"
		echo
		sleep 3
		cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/depends
		if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
		hide_output make -j$NPROC
		else
		make -j$NPROC
		fi
		echo
		echo
		echo -e "$GREEN Done...$COL_RESET"

		# Building autogen....
		echo
		echo -e "$YELLOW => Building autogen... $COL_RESET"
		echo
		sleep 3
		cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}
		if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
		hide_output sh autogen.sh
		else
		sh autogen.sh
		fi
		echo
		echo
		echo -e "$GREEN Done...$COL_RESET"

		# Configure with your platform....
		if [ -d "$DEPENDS/i686-pc-linux-gnu" ]; then
			echo
			echo -e "$YELLOW => Configure with i686-pc-linux-gnu... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/i686-pc-linux-gnu
			else
			./configure --prefix=`pwd`/depends/i686-pc-linux-gnu
			fi
		elif [ -d "$DEPENDS/x86_64-pc-linux-gnu/" ]; then
			echo
			echo -e "$YELLOW => Configure with x86_64-pc-linux-gnu... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/x86_64-pc-linux-gnu
			else
			./configure --prefix=`pwd`/depends/x86_64-pc-linux-gnu
			fi
		elif [ -d "$DEPENDS/i686-w64-mingw32/" ]; then
			echo
			echo -e "$YELLOW => Configure with i686-w64-mingw32... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/i686-w64-mingw32
			else
			./configure --prefix=`pwd`/depends/i686-w64-mingw32
			fi
		elif [ -d "$DEPENDS/x86_64-w64-mingw32/" ]; then
			echo
			echo -e "$YELLOW => Configure with x86_64-w64-mingw32... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/x86_64-w64-mingw32
			else
			./configure --prefix=`pwd`/depends/x86_64-w64-mingw32
			fi
		elif [ -d "$DEPENDS/x86_64-apple-darwin14/" ]; then
			echo
			echo -e "$YELLOW => Configure with x86_64-apple-darwin14... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/x86_64-apple-darwin14
			else
			./configure --prefix=`pwd`/depends/x86_64-apple-darwin14
			fi
		elif [ -d "$DEPENDS/arm-linux-gnueabihf/" ]; then
			echo
			echo -e "$YELLOW => Configure with arm-linux-gnueabihf... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/arm-linux-gnueabihf
			else
			./configure --prefix=`pwd`/depends/arm-linux-gnueabihf
			fi
		elif [ -d "$DEPENDS/aarch64-linux-gnu/" ]; then
			echo
			echo -e "$YELLOW => Configure with aarch64-linux-gnu... $COL_RESET"
			echo
			sleep 3
			if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
			hide_output ./configure --prefix=`pwd`/depends/aarch64-linux-gnu
			else
			./configure --prefix=`pwd`/depends/aarch64-linux-gnu
			fi
		fi
		echo
		echo
		echo -e "$GREEN Done...$COL_RESET"
		
		# Executing make to finalize....
		echo
		echo -e "$YELLOW => Executing make to finalize... $COL_RESET"
		echo
		sleep 3
		if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
		hide_output make -j$NPROC
		else
		make -j$NPROC
		fi
		echo
		echo
		echo -e "$GREEN Done...$COL_RESET"
	else
		echo
		echo "Building using Cmake method..."
		echo
		echo
		sleep 3
		cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir} && git submodule init && git submodule update
		make -j$NPROC
		sleep 3
	fi
fi
	if [[ ("$unix" == "true") ]]; then
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

if [[ ("$precompiled" == "true") ]]; then
	COINTARGZ=$(find ~+ -type f -name "*.tar.gz")
	COINZIP=$(find ~+ -type f -name "*.zip")
	if [[ -f "$COINZIP" ]]; then
		for i in $(ls -f *.zip); do coinzipped=${i%%}; done
		sudo unzip -q $coinzipped -d newcoin
		for i in $(ls -d */); do repzipcoin=${i%%/}; done
	elif [[ -f "$COINTARGZ" ]]; then
		for i in $(ls -f *.tar.gz); do coinzipped=${i%%}; done
		sudo tar xzvf $coinzipped
		for i in $(ls -d */); do repzipcoin=${i%%/}; done
	else
		echo -e "$RED => This is a not valid file zipped $COL_RESET"
	fi
fi

clear

# LS the SRC dir to have user input bitcoind and bitcoin-cli names
if [[ ! ("$precompiled" == "true") ]]; then

	cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/
	
	find . -maxdepth 1 -type f ! -name "*.*" \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
	read -r -e -p "Please enter the coind name from the directory above, example bitcoind :" coind
	read -r -e -p "Is there a coin-cli, example bitcoin-cli [y/N] :" ifcoincli

		if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
			read -r -e -p "Please enter the coin-cli name :" coincli
		fi

		read -r -e -p "Is there a coin-tx, example bitcoin-tx [y/N] :" ifcointx

		if [[ ("$ifcointx" == "y" || "$ifcointx" == "Y") ]]; then
			read -r -e -p "Please enter the coin-tx name :" cointx
		fi

		if [[ ("$berkeley" == "6.2" || "$precompiled" == "true") ]]; then
			read -r -e -p "Is there a coin-tools, example bitcoin-wallet-tools [y/N] :" ifcointools

		if [[ ("$ifcointools" == "y" || "$ifcointools" == "Y") ]]; then
			read -r -e -p "Please enter the coin-tools name :" cointools
		fi

		read -r -e -p "Is there a coin-gtest, example bitcoin-gtest [y/N] :" ifcoingtest

		if [[ ("$ifcoingtest" == "y" || "$ifcoingtest" == "Y") ]]; then
			read -r -e -p "Please enter the coin-gtest name :" coingtest
		fi
	fi

fi

clear

# Strip and copy to /usr/bin
if [[ ("$precompiled" == "true") ]]; then
	cd $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/${repzipcoin}/
	
	COINDFIND=$(find ~+ -type f -name "*d")
	COINCLIFIND=$(find ~+ -type f -name "*-cli")
	COINTXFIND=$(find ~+ -type f -name "*-tx")
	
	coind=$(basename $COINDFIND)

	sudo strip $COINDFIND
	sudo cp $COINDFIND /usr/bin
	sudo chmod +x /usr/bin/${coind}
	
	if [[ -f "$COINCLIFIND" ]]; then
		coincli=$(basename $COINCLIFIND)
		sudo strip $COINCLIFIND
		sudo cp $COINCLIFIND /usr/bin
		sudo chmod +x /usr/bin/${coincli}
	fi

	if [[ -f "$COINTXFIND" ]]; then
		cointx=$(basename $COINTXFIND)
		sudo strip $COINTXFIND
		sudo cp $COINTXFIND /usr/bin
		sudo chmod +x /usr/bin/${cointx}
	fi
else
	sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind}
	sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin

	if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
	  sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli}
	  sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
	fi

	if [[ ("$ifcointx" == "y" || "$ifcointx" == "Y") ]]; then
		sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointx}
		sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointx} /usr/bin
	fi

	if [[ ("$ifcoingtest" == "y" || "$ifcoingtest" == "Y") ]]; then
		sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest}
		sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest} /usr/bin
	fi

	if [[ ("$ifcointools" == "y" || "$ifcointools" == "Y") ]]; then
		sudo strip $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointools}
		sudo cp $HOME/utils/daemon_builder/temp_coin_builds/${coindir}/src/${cointools} /usr/bin
	fi
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
cd $HOME/utils/daemon_builder
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
