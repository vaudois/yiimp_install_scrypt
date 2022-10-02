#!/usr/bin/env bash
#####################################################
# Created by Vaudois
# Source to compile wallets
#####################################################

source ${absolutepath}/${installtoserver}/conf/info.sh

FUNC=/etc/functionscoin.sh
if [[ ! -f "$FUNC" ]]; then
	source /etc/functions.sh
else
	source /etc/functionscoin.sh
fi

YIIMPOLL=/etc/yiimpool.conf
if [[ -f "$YIIMPOLL" ]]; then
	source /etc/yiimpool.conf
	YIIMPCONF=true
fi

# Set what we need
now=$(date +"%m_%d_%Y")
#set -e
NPROC=$(nproc)
# Create the temporary installation directory if it doesn't already exist.
echo
echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$YELLOW   Creating the temporary build folder... 									$COL_RESET"
echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"

source ${absolutepath}/${installtoserver}/daemon_builder/.my.cnf

if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds" ]]; then
	sudo mkdir -p ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds
else
	sudo rm -rf ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/*
	echo
	echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
	echo -e "$GREEN   temp_coin_builds already exists.... Skipping 								$COL_RESET"
	echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
fi
# Just double checking folder permissions
sudo setfacl -m u:$USER:rwx ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds
cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds

# Get the github information
	input_box " COIN NAME " \
	"Enter the name of the coin.
	\n\nExample: Bitcoin or btc...
	\n\n*Paste press CTRL and right bottom Mouse.
	\n\nCoin name:" \
	"" \
	coin

if [[ ("${precompiled}" == "true") ]]; then
	input_box " PRECOMPILED COIN " \
	"Paste url coin precompiled file format compressed!
	\n\nFormat *.tar.gz OR *.zip
	\n\nCoin url link:" \
	"" \
	coin_precompiled
else
	input_box " GITHUB LINK " \
	"Paste url coin link from github
	\n\nhttps://github.com/example-repo-name/coin-wallet.git
	\n\nCoin url link:" \
	"" \
	git_hub

	dialog --title " Switch To develeppement " \
	--yesno "Switch from main repo git in to develop ?
	Selecting Yes use Git develeppements." 6 50
	response=$?
	case $response in
	   0) swithdevelop=yes;;
	   1) swithdevelop=no;;
	   255) echo "[ESC] key pressed.";;
	esac

	if [[ ("${swithdevelop}" == "no") ]]; then
	
		dialog --title " Use a specific branch " \
		--yesno "Do you need to use a specific github branch of the coin?
		Selecting Yes use a selected version Git." 7 60
		response=$?
		case $response in
		   0) branch_git_hub=yes;;
		   1) branch_git_hub=no;;
		   255) echo "[ESC] key pressed.";;
		esac
	
		if [[ ("${branch_git_hub}" == "yes") ]]; then

			input_box " Branch Version " \
			"Please enter the branch name exactly as in github
			\n\nExample v2.5.1
			\n\nBranch version:" \
			"" \
			branch_git_hub_ver
		fi
	fi
fi

set -e
clear
echo
echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Starting installation coin : ${coin^^}							$COL_RESET"
echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
	
coindir=$coin$now

# save last coin information in case coin build fails
echo '
lastcoin='"${coindir}"'
' | sudo -E tee ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

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

	if [[ ("${branch_git_hub}" == "yes") ]]; then
	  git fetch
	  git checkout "$branch_git_hub_ver"
	fi

	if [[ ("${swithdevelop}" == "yes") ]]; then
	  git checkout develop
	fi
	errorexist="false"
else
echo
	message_box " Coin already exist temp folder " \
	"${coindir} already exists.... in temp folder Skipping Installation!
	\n\nIf there was an error in the build use the build error options on the installer."

	errorexist="true"
	exit 0
fi

if [[("${errorexist}" == "false")]]; then
	sudo chmod -R 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}
fi

# Build the coin under the proper configuration
if [[ ("$autogen" == "true") ]]; then

	# Build the coin under berkeley 4.8
	if [[ ("$berkeley" == "4.8") ]]; then

		echo "Building using Berkeley 4.8..."
		basedir=$(pwd)
		sh autogen.sh

		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
		  echo "genbuild.sh not found skipping"
		else
			sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
		fi
		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
		  echo "build_detect_platform not found skipping"
		else
		sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
		fi
		./configure CPPFLAGS="-I${absolutepath}/${installtoserver}/berkeley/db4/include -O2" LDFLAGS="-L${absolutepath}/${installtoserver}/berkeley/db4/lib" --without-gui --disable-tests
	fi

	# Build the coin under berkeley 5.1
	if [[ ("$berkeley" == "5.1") ]]; then

		echo "Building using Berkeley 5.1..."
		basedir=$(pwd)
		sh autogen.sh
		
		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
			echo "genbuild.sh not found skipping"
		else
			sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
		fi
		
		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
			echo "build_detect_platform not found skipping"
		else
			sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
		fi
		./configure CPPFLAGS="-I${absolutepath}/${installtoserver}/berkeley/db5/include -O2" LDFLAGS="-L${absolutepath}/${installtoserver}/berkeley/db5/lib" --without-gui --disable-tests
	fi

	# Build the coin under berkeley 5.3
	if [[ ("$berkeley" == "5.3") ]]; then
		echo "Building using Berkeley 5.3..."
		basedir=$(pwd)
		sh autogen.sh

		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
			echo "genbuild.sh not found skipping"
		else
			sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
		fi
		
		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
			echo "build_detect_platform not found skipping"
		else
			sudo chmod 777 ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
		fi
		./configure CPPFLAGS="-I${absolutepath}/${installtoserver}/berkeley/db5.3/include -O2" LDFLAGS="-L${absolutepath}/${installtoserver}/berkeley/db5.3/lib" --without-gui --disable-tests
	fi

	# Build the coin under berkeley 6.2
	if [[ ("$berkeley" == "6.2") ]]; then
		echo "Building using Berkeley 6.2..."
		basedir=$(pwd)
		sh autogen.sh

		find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
		read -r -e -p "where is the folder that contains the BUILD.SH installation file, example xxutil :" reputil
		cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/${reputil}
		echo ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/${reputil}
		spiner_output bash build.sh -j$(nproc)
		
		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/${reputil}/fetch-params.sh" ]]; then
			echo "fetch-params.sh not found skipping"
		else
			sh fetch-params.sh
		fi
	fi

	# make install
	if [[ ("$berkeley" != "6.2") ]]; then
		make -j$(nproc)
	fi
else

	# Build the coin under cmake
	if [[ ("$cmake" == "true") ]]; then
		clear
		DEPENDS="${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/depends"

		# Build the coin under depends present
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
			cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/depends
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
			cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}
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
			cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir} && git submodule init && git submodule update
			make -j$NPROC
			sleep 3
		fi
	fi

	# Build the coin under unix
	if [[ ("$unix" == "true") ]]; then
		echo "Building using makefile.unix method..."
		cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src

		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/obj" ]]; then
			mkdir -p ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/obj
		else
			echo "Hey the developer did his job and the src/obj dir is there!"
		fi

		if [[ ! -e "${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin" ]]; then
			mkdir -p ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin
		else
			echo  "Wow even the /src/obj/zerocoin is there! Good job developer!"
		fi

		cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/leveldb
		sudo chmod +x build_detect_platform
		echo
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		echo -e "$GREEN   Starting make clean...														$COL_RESET"
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		sleep 3
		sudo make clean
		echo
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		echo -e "$GREEN   Starting precompiling with make depends libs*									$COL_RESET"
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		sleep 3
		sudo make libleveldb.a libmemenv.a
		cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src
		sed -i '/USE_UPNP:=0/i BDB_LIB_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/lib\nBDB_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/include\nOPENSSL_LIB_PATH = '${absolutepath}'/'${installtoserver}'/openssl/lib\nOPENSSL_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/openssl/include' makefile.unix
		sed -i '/USE_UPNP:=1/i BDB_LIB_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/lib\nBDB_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/include\nOPENSSL_LIB_PATH = '${absolutepath}'/'${installtoserver}'/openssl/lib\nOPENSSL_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/openssl/include' makefile.unix
		echo
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		echo -e "$GREEN   Starting compiling with makefile.unix											$COL_RESET"
		echo -e "$CYAN ------------------------------------------------------------------------------- 	$COL_RESET"
		sleep 3
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

	cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/
	
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
	cd ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/${repzipcoin}/
	
	COINDFIND=$(find ~+ -type f -name "*d")
	COINCLIFIND=$(find ~+ -type f -name "*-cli")
	COINTXFIND=$(find ~+ -type f -name "*-tx")
	
	if [[ -f "$COINDFIND" ]]; then
		coind=$(basename $COINDFIND)

		sudo strip $COINDFIND
		sudo cp $COINDFIND /usr/bin
		sudo chmod +x /usr/bin/${coind}
		coindmv=true

		echo
		echo
		echo -e "$GREEN Coind moving to /usr/bin/$COL_RESET$YELLOW${coind} $COL_RESET"
		sleep 3
	else
		clear

		echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
		echo -e "$RED    ERROR																		$COL_RESET"
		echo -e "$RED    your precompiled *zip OR *.tar.gz not contains coind file					$COL_RESET"
		echo -e "$RED    Please start again with a valid file precompiled!							$COL_RESET"
		echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"

		sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/.lastcoin.conf
		sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}
		sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/.my.cnf

		exit;
	fi
	
	if [[ -f "$COINCLIFIND" ]]; then
		coincli=$(basename $COINCLIFIND)
		sudo strip $COINCLIFIND
		sudo cp $COINCLIFIND /usr/bin
		sudo chmod +x /usr/bin/${coincli}
		coinclimv=true
		
		echo
		echo
		echo -e "$GREEN Coin-cli moving to /usr/bin/$COL_RESET$YELLOW${coincli} $COL_RESET"
		sleep 3
	fi

	if [[ -f "$COINTXFIND" ]]; then
		cointx=$(basename $COINTXFIND)
		sudo strip $COINTXFIND
		sudo cp $COINTXFIND /usr/bin
		sudo chmod +x /usr/bin/${cointx}
		cointxmv=true
		
		echo
		echo
		echo -e "$GREEN Coin-tx moving to /usr/bin/$COL_RESET$YELLOW${cointx} $COL_RESET"
		sleep 3
	fi
else
	sudo strip ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coind}
	sudo cp ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin
	coindmv=true

	if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
	  sudo strip ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coincli}
	  sudo cp ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
	  coinclimv=true
	fi

	if [[ ("$ifcointx" == "y" || "$ifcointx" == "Y") ]]; then
		sudo strip ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${cointx}
		sudo cp ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${cointx} /usr/bin
		cointxmv=true
	fi

	if [[ ("$ifcoingtest" == "y" || "$ifcoingtest" == "Y") ]]; then
		sudo strip ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest}
		sudo cp ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${coingtest} /usr/bin
		coingtestmv=true
	fi

	if [[ ("$ifcointools" == "y" || "$ifcointools" == "Y") ]]; then
		sudo strip ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${cointools}
		sudo cp ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}/src/${cointools} /usr/bin
		cointoolsmv=true
	fi
fi

if [[ ("${YIIMPCONF}" == "true") ]]; then
	# Make the new wallet folder have user paste the coin.conf and finally start the daemon
	if [[ ! -e '$STORAGE_ROOT/wallets' ]]; then
		sudo mkdir -p $STORAGE_ROOT/wallets
	fi

	sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/wallets
	sudo mkdir -p $STORAGE_ROOT/wallets/."${coind::-1}"
elif [[ ("INSTALLMASTER" == "true") ]]; then
	# Make the new wallet folder have user paste the coin.conf and finally start the daemon
	if [[ ! -e "/home/wallets" ]]; then
		sudo mkdir -p /home/wallets
	fi

	sudo setfacl -m u:$USER:rwx /home/wallets
	sudo mkdir -p /home/wallets/."${coind::-1}"
else
	# Make the new wallet folder have user paste the coin.conf and finally start the daemon
	if [[ ! -e "${absolutepath}/wallets" ]]; then
		sudo mkdir -p ${absolutepath}/wallets
	fi

	sudo setfacl -m u:$USER:rwx ${absolutepath}/wallets
	sudo mkdir -p ${absolutepath}/wallets/."${coind::-1}"
fi

echo
echo
echo -e "$CYAN --------------------------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$YELLOW   I am now going to open nano, please copy and paste the config from yiimp in to this file.	$COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------------------------- 	$COL_RESET"
echo
read -n 1 -s -r -p "Press any key to continue"
echo

if [[ "${YIIMPCONF}" == "true" ]]; then
	sudo nano $STORAGE_ROOT/wallets/."${coind::-1}"/${coind::-1}.conf
elif [[ ("INSTALLMASTER" == "true") ]]; then
	sudo nano home/wallets/."${coind::-1}"/${coind::-1}.conf
else
	sudo nano ${absolutepath}/wallets/."${coind::-1}"/${coind::-1}.conf
fi

clear
cd ${absolutepath}/${installtoserver}/daemon_builder

clear
echo
echo
figlet -f slant -w 100 "   Yeah!"

echo -e "$CYAN --------------------------------------------------------------------------- 	"
echo -e "$CYAN    Starting ${coind::-1} $COL_RESET"
echo -e "$COL_RESET $GREEN   Installation of ${coind::-1} is completed and running. $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
if [[ "$coindmv" == "true" ]] ; then
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Name of COIND : ${coind} $COL_RESET"
echo -e "$GREEN   path in : /usr/bin/${coind} $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
fi
if [[ "$coinclimv" == "true" ]] ; then
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Name of COIN-CLI : ${coincli} $COL_RESET"
echo -e "$GREEN   path in : /usr/bin/${coincli} $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
fi
if [[ "$cointxmv" == "true" ]] ; then
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Name of COIN-TX : ${cointx} $COL_RESET"
echo -e "$GREEN   path in : /usr/bin/${cointx} $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
fi
if [[ "$coingtestmv" == "true" ]] ; then
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Name of COIN-TX : ${coingtest} $COL_RESET"
echo -e "$GREEN   path in : /usr/bin/${coingtest} $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
fi
if [[ "$cointoolsmv" == "true" ]] ; then
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$GREEN   Name of COIN-TX : ${cointools} $COL_RESET"
echo -e "$GREEN   path in : /usr/bin/${cointools} $COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo
fi
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo -e "$RED    Type ${daemonname} at anytime to install a new coin! 				$COL_RESET"
echo -e "$CYAN --------------------------------------------------------------------------- 	$COL_RESET"
echo

# If we made it this far everything built fine removing last coin.conf and build directory
sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/.lastcoin.conf
sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/temp_coin_builds/${coindir}
sudo rm -r ${absolutepath}/${installtoserver}/daemon_builder/.my.cnf

echo
echo
if [[ ("${YIIMPCONF}" == "true") ]]; then
	"${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile
elif [[ ("INSTALLMASTER" == "true") ]]; then
	"${coind}" -datadir=/home/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile
else
	"${coind}" -datadir=${absolutepath}/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile
fi
echo

exit
