#!/bin/bash
#################################################################################
# Author: Vaudois
#
# Program:
#   Install yiimp on Ubuntu 20.04 & 22.04 running Nginx, MariaDB, and PHP 8.2/8.3
#   v2.2.9 beta
#   Modified for include aarch64 compatibility
#################################################################################

if [ -z "${TAG}" ]; then
    TAG=v2.2.9_beta
fi

NPROC=$(nproc)

clear

source utils/swap.sh
make_swap
sleep 3
clear

    ### Variable ###
    githubyiimptpruvot=https://github.com/tpruvot/yiimp.git
    githubrepoKudaraidee=https://github.com/Kudaraidee/yiimp.git
    githubrepoAfinielTech=https://github.com/Afiniel-tech/yiimp.git
    githubrepoAfiniel=https://github.com/afiniel/yiimp.git
    githubrepoSabiasQue=https://github.com/SabiasQueSpace/yiimp.git
    githubrepoTpfuemp=https://github.com/tpfuemp/yiimp.git
    
    githubstratum=https://github.com/vaudois/stratum.git

    echo "Starting installer..."
    
    BTCDEP="bc1qt8g9l6agk7qrzlztzuz7quwhgr3zlu4gc5qcuk"
    LTCDEP="MGyth7od68xVqYnRdHQYes22fZW2b6h3aj"
    ETHDEP="0xc4e42e92ef8a196eef7cc49456c786a41d7daa01"
    BCHDEP="bitcoincash:qp9ltentq3rdcwlhxtn8cc2rr49ft5zwdv7k7e04df"

    nameofinstall=yiimp_install_scrypt
    daemonname=coinbuild
    absolutepath=$HOME
    installtoserver=coin-setup
    
    sudo sed -i 's#btcdons#'$BTCDEP'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#ltcdons#'$LTCDEP'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#ethdons#'$ETHDEP'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#bchdons#'$BCHDEP'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#daemonnameserver#'$daemonname'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#installpath#'$installtoserver'#' conf/functions.sh
    sleep 1
    
    sudo sed -i 's#absolutepathserver#'$absolutepath'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#versiontag#'$TAG'#' conf/functions.sh
    sleep 1

    sudo sed -i 's#versiontag#'$TAG'#' conf/update-motd.d/00-header
    sleep 1

    output()
    {
        printf "\E[0;33;40m"
        echo $1
        printf "\E[0m"
    }

    displayErr()
    {
        echo
        echo $1;
        echo
        exit 1;
    }

    # Check for resume mode
    RESUME_MODE=false
    if [[ "$1" == "r" ]]; then
        RESUME_MODE=true
        PARAMS_FILE="${absolutepath}/${installtoserver}/resume/install_params.conf"
        if [[ ! -f "$PARAMS_FILE" ]]; then
            echo -e "$RED Error: Resume mode requested but parameter file ($PARAMS_FILE) does not exist. Cannot resume installation.$COL_RESET"
            exit 1
        fi
        echo -e "$CYAN Loading parameters from $PARAMS_FILE for resume...$COL_RESET"
        source "$PARAMS_FILE"
        # Validate required parameters
        required_params=("server_name" "sub_domain" "EMAIL" "admin_panel" "Public" "install_fail2ban" "ssl_install" "wg_install" "yiimpver")
        for param in "${required_params[@]}"; do
            if [[ -z "${!param}" ]]; then
                echo -e "$RED Error: Missing parameter $param in $PARAMS_FILE.$COL_RESET"
                exit 1
            fi
        done
    else
        # Ensure parameter file is removed in normal mode to avoid conflicts
        sudo rm -f "${absolutepath}/${installtoserver}/resume/install_params.conf" >/dev/null 2>&1
    fi

    # Source necessary files
    if [[ "$RESUME_MODE" == "true" ]]; then
        source /etc/functions.sh
        source conf/prerequisite.sh
        sleep 3
        source conf/getip.sh
        source utils/packagecompil.sh
        source conf/configs.sh
    else
		sudo cp -r conf/functions.sh /etc/
        source conf/functions.sh
        source conf/prerequisite.sh
        sleep 3
        source conf/getip.sh
        source utils/packagecompil.sh
        source conf/configs.sh
    fi

    # Add user group sudo + no password
    whoami=$(whoami)
    sudo usermod -aG sudo ${whoami}
    echo '# yiimp
    # It needs passwordless sudo functionality.
    '""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
    ' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

    # Copy needed files
    sudo cp -r conf/functions.sh /etc/
    sudo cp -r conf/screen-scrypt.sh /etc/
    sudo cp -r conf/editconf.py /usr/bin/
    sudo cp -r utils/blocknotify.sh /usr/bin/
    sudo chmod +x /usr/bin/editconf.py
    sudo chmod +x /etc/screen-scrypt.sh
    sudo chmod +x /usr/bin/blocknotify.sh
    
    sudo mkdir /var/log/yiimp/ >/dev/null 2>&1
    sudo chgrp ${whoami} /var/log/yiimp
    sudo chown ${whoami} /var/log/yiimp
    sudo touch /var/log/yiimp/debug.log
    sudo chgrp www-data /var/log/yiimp -R
    sudo chmod 775 /var/log/yiimp -R

    # Get user parameters
    if [[ "$RESUME_MODE" == "false" ]]; then
        clear
        term_art_server

        echo
        echo -e "$RED Make sure you double check before hitting enter! Only one shot at these! $COL_RESET"
        echo
		while true; do
			read -e -p "Enter domain name or IP (e.g., example.com, example.local, or ${PUBLIC_IP}): " server_name
			if [[ -n "$server_name" && "$server_name" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ || "$server_name" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$server_name" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.local$ ]]; then
				if [[ "$server_name" =~ ^(https?://|www\.) ]]; then
					echo "Error: Do not include 'https://' or 'www.' in the domain name."
				else
					break
				fi
			else
				echo "Error: Please enter a valid domain (e.g., example.com, example.local) or IP (e.g., ${PUBLIC_IP})."
			fi
		done
        read -e -p "Enter subdomain for stratum connections (e.g. europe) [N => not subdomain] : " sub_domain
		while true; do
			read -e -p "Enter support email (e.g., admin@example.com): " EMAIL
			if [[ -n "$EMAIL" && "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
				break
			else
				echo "Error: Please enter a valid email address (e.g., admin@example.com)."
			fi
		done
        read -e -p "Admin panel: enter custom URL name (press Enter for default: myAdminpanel): " admin_panel
		admin_panel=${admin_panel:-myAdminpanel}
		while true; do
			read -e -p "Enter IP for admin panel access (Enter for default: 0.0.0.0/0): " Public
			Public=${Public:-0.0.0.0/0}
			
			# Validate IP or CIDR format (basic regex)
			if [[ "$Public" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ || "$Public" == "0.0.0.0/0" ]]; then
				break
			else
				echo "Error: Invalid IP or CIDR. Use format like 192.168.1.100 or 10.0.0.0/24."
			fi
		done
        read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
        read -e -p "Install SSL? IMPORTANT! Have your domain name pointed to this server prior! [Y/n]: " ssl_install
        read -e -p "Install Wireguard for future remote stratums??? [y/N]: " wg_install
        if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
            read -e -p "Enter a Local Wireguard Private IP for this server (${PRIVATE_IP}): " wg_ip
        else
            wg_ip=""
        fi

		# Stylish prompt for Yiimp version selection
		echo -e "${CYAN}======================================${COL_RESET}"
		echo -e "${CYAN}      Select Yiimp Install Version     ${COL_RESET}"
		echo -e "${CYAN}======================================${COL_RESET}"
		echo -e "${GREEN}  1. Kudaraidee (error white page)    ${COL_RESET}"
		echo -e "${GREEN}  2. tpruvot                         ${COL_RESET}"
		echo -e "${GREEN}  3. Afiniel-Tech                    ${COL_RESET}"
		echo -e "${GREEN}  4. Afiniel                         ${COL_RESET}"
		echo -e "${GREEN}  5. SabiasQue                       ${COL_RESET}"
		echo -e "${GREEN}  6. Tpfuemp (default)               ${COL_RESET}"
		echo -e "${CYAN}======================================${COL_RESET}"

		while true; do
			echo -en "${YELLOW}Enter your choice (1-6) [6 by default]: ${COL_RESET}"
			read yiimpver
			# Set default to 6 if empty
			yiimpver=${yiimpver:-6}
			# Check if input is a number between 1 and 6
			if [[ "$yiimpver" =~ ^[1-6]$ ]]; then
				break
			else
				echo -e "${RED}--------------------------------------${COL_RESET}"
				echo -e "${RED}Error: Please enter a number between 1 and 6.${COL_RESET}"
				echo -e "${RED}--------------------------------------${COL_RESET}"
			fi
		done

		echo -e "${BLUE}Selected Yiimp version: $yiimpver${COL_RESET}"

        clear
        term_art_server
        if [[ ("$yiimpver" -gt "6" || "$yiimpver" -lt "1") ]]; then
            echo ""
            echo ""
            echo -e "$RED  SELECTED $yiimpver it is not correct you have to choose between 1 to 6 !!!!...$COL_RESET"
            echo -e "$YELLOW  RESTARTING your install again... $COL_RESET"
            echo ""
            sleep 7
            bash install.sh
        fi
        echo -e "\n\n"
        echo -e "$RED You entered the following. If it's wrong CTRL-C now to start over $COL_RESET"
        echo "Domain Name:         $server_name"
        echo "Stratum Subdomain:   $sub_domain"
        echo "Support Email:       $EMAIL"
        echo "Panel Url:           $admin_panel"
        echo "IP Range for Admin:  $Public"
        echo "Install Fail2ban:    $install_fail2ban"
        echo "Install SSL now:     $ssl_install"
        echo "Install wiregauard:  $wg_install"
        if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
            echo "Wireguard wg0 IP:    $wg_ip"
        fi
        echo "Yiimp Github choice: $yiimpver"

        read -e -p "Press ENTER to continue or CTRL-C to exit and start over" dummy
        echo -e "\n\n"

        # Save parameters to file
        sudo mkdir -p ${absolutepath}/${installtoserver}/resume >/dev/null 2>&1
        echo "server_name='$server_name'" | sudo tee ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "sub_domain='$sub_domain'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "EMAIL='$EMAIL'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "admin_panel='$admin_panel'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "Public='$Public'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "install_fail2ban='$install_fail2ban'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "ssl_install='$ssl_install'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "wg_install='$wg_install'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "wg_ip='$wg_ip'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        echo "yiimpver='$yiimpver'" | sudo tee -a ${absolutepath}/${installtoserver}/resume/install_params.conf >/dev/null 2>&1
        sudo chmod 600 ${absolutepath}/${installtoserver}/resume/install_params.conf
        sudo chown ${whoami} ${absolutepath}/${installtoserver}/resume/install_params.conf
        log_message "Saved installation parameters to ${absolutepath}/${installtoserver}/resume/install_params.conf"
    fi

    clear
    term_art_server

    if [[ "$RESUME_MODE" == "true" ]]; then
        echo -e "$CYAN Resuming installation at CoinBuild step...$COL_RESET"
        cd ${absolutepath}/${nameofinstall}
        STRATUMFILE=/var/stratum
        sudo git config --global url."https://github.com/".insteadOf git@github.com: >/dev/null 2>&1
        sudo git config --global url."https://".insteadOf git:// >/dev/null 2>&1
        sleep 2
    else
        # Update package and Upgrade Ubuntu
        echo
        echo -e "$CYAN => Installing base system packages for Yiimp :$COL_RESET"
        sleep 3

	simple_hide_output "Updating apt..." sudo apt -y update
	simple_hide_output "Upgrading apt..." sudo apt -y upgrade
        apt_install dialog python3 python3-pip acl nano apt-transport-https update-notifier-common
        apt_install figlet curl jq update-motd pwgen
        log_message "Installed base system packages"
        echo -e "$GREEN Done...$COL_RESET"

        echo 'PUBLIC_IP='"${PUBLIC_IP}"'
        PUBLIC_IPV6='"${PUBLIC_IPV6}"'
        DISTRO='"${DISTRO}"'
        PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee conf/pool.conf >/dev/null 2>&1

        # Switch Aptitude
        echo
        echo -e "$CYAN Switching to Aptitude $COL_RESET"
        sleep 3
        apt_install aptitude
        log_message "Installed aptitude"
        echo -e "$GREEN Done...$COL_RESET"

        # Installing Nginx
        echo
        echo -e "$CYAN => Installing Nginx server : $COL_RESET"
        sleep 3
        
        if [ -f /usr/sbin/apache2 ]; then
            echo -e "Removing apache..."
            hide_output apt-get -y purge apache2 apache2-*
            hide_output apt-get -y --purge autoremove
            log_message "Removed Apache"
        fi

        apt_install nginx

		# Remove /etc/nginx/repos-enabled/default.conf if it exists
		if [ -f /etc/nginx/repos-enabled/default.conf ]; then
			hide_output "Removing default configuration file..." sudo rm -f /etc/nginx/repos-enabled/default.conf
		fi

		# Manage nginx.service
		if systemctl is-active --quiet nginx.service; then
			hide_output "Restarting nginx..." sudo systemctl restart nginx.service
		else
			hide_output "Starting nginx..." sudo systemctl start nginx.service
		fi

		if ! systemctl is-enabled --quiet nginx.service; then
			hide_output "Enabling nginx..." sudo systemctl enable nginx.service
		fi

		# Manage cron.service
		if systemctl is-active --quiet cron.service; then
			hide_output "Restarting cron..." sudo systemctl restart cron.service
		else
			hide_output "Starting cron..." sudo systemctl start cron.service
		fi

		if ! systemctl is-enabled --quiet cron.service; then
			hide_output "Enabling cron..." sudo systemctl enable cron.service
		fi

        sudo systemctl status nginx | sed -n "1,3p"
        log_message "Installed and started Nginx"
        echo -e "$GREEN Done...$COL_RESET"

        # Making Nginx a bit hard
        echo 'map $http_user_agent $blockedagent
        {
            default         0;
            ~*malicious     1;
            ~*bot           1;
            ~*backdoor      1;
            ~*crawler       1;
            ~*bandit        1;
        }' | sudo -E tee /etc/nginx/blockuseragents.rules >/dev/null 2>&1
        log_message "Configured Nginx user agent blocking"

        # Installing Mariadb
        echo
        echo -e "$CYAN => Installing Mariadb Server : $COL_RESET"
        sleep 3

        # Create random password
        rootpasswd=$(openssl rand -base64 12)
        export DEBIAN_FRONTEND="noninteractive"
        apt_install mariadb-server

		# Manage mysql.service
		if systemctl is-active --quiet mysql.service; then
			hide_output "Restarting mysql..." sudo systemctl restart mysql.service
		else
			hide_output "Starting mysql..." sudo systemctl start mysql.service
		fi

		if ! systemctl is-enabled --quiet mysql.service; then
			hide_output "Enabling mysql..." sudo systemctl enable mysql.service
		fi

        sleep 5
        sudo systemctl status mysql | sed -n "1,3p"
        log_message "Installed and started MariaDB"
        echo -e "$GREEN Done...$COL_RESET"

        # Installing PHP and other files
        echo
        echo -e "$CYAN => Update system & Install PHP & software-properties $COL_RESET"
        sleep 3

        apt_install software-properties-common

		if [ ! -f /etc/apt/sources.list.d/ondrej-php.list ]; then
			simple_hide_output "Adding ondrej/php PPA..." sudo add-apt-repository -y ppa:ondrej/php
			simple_hide_output "Updating apt..." sudo apt -y update
			log_message "Added ondrej/php PPA"
		fi
        echo -e "$YELLOW >--> Installing php...$COL_RESET"
        if [[ "$DISTRO" == "20" ]]; then
            apt_install php8.2-fpm php8.2-opcache php8.2 php8.2-common php8.2-gd php8.2-mysql php8.2-imap php8.2-cli
            apt_install php8.2-cgi php8.2-curl php8.2-intl php8.2-pspell
            apt_install php8.2-sqlite3 php8.2-tidy php8.2-xml php8.2-zip
            apt_install php8.2-mbstring php8.2-memcache php8.2-memcached memcached php-memcache php-memcached
			sudo phpenmod -v 8.2 mbstring
			sudo phpenmod -v 8.2 memcache memcached
            apt_install php8.2-gettext
			simple_hide_output sudo update-alternatives --set php /usr/bin/php8.2
            simple_hide_output sudo systemctl start php8.2-fpm
            sudo systemctl status php8.2-fpm | sed -n "1,3p"
            PHPVERSION=8.2
            log_message "Installed PHP 8.2 and dependencies"
        elif [[ "$DISTRO" == "22" ]]; then
            apt_install php8.3-fpm php8.3-opcache php8.3 php8.3-common php8.3-gd php8.3-mysql php8.3-imap php8.3-cli
            apt_install php8.3-cgi php8.3-curl php8.3-intl php8.3-pspell
            apt_install php8.3-sqlite3 php8.3-tidy php8.3-xml php8.3-zip
            apt_install php8.3-mbstring php8.3-memcache php8.3-memcached memcached php-memcache php-memcached
			# Activer les modules nécessaires pour PHP 8.3
			sudo phpenmod -v 8.3 mbstring
			sudo phpenmod -v 8.3 memcache memcached
			apt_install php8.3-gettext
			simple_hide_output sudo update-alternatives --set php /usr/bin/php8.3
            simple_hide_output sudo systemctl start php8.3-fpm
            sudo systemctl status php8.3-fpm | sed -n "1,3p"
            PHPVERSION=8.3
            log_message "Installed PHP 8.3 and dependencies"
        fi

        sleep 5
        echo -e "$GREEN Done...$COL_RESET"

        # Fix CDbConnection failed to open the DB connection.
        echo
        echo -e "$CYAN => Fixing DBconnection issue $COL_RESET"
        if [[ "$DISTRO" == "20" ]]; then
            apt_install php8.2-mysql
        elif [[ "$DISTRO" == "22" ]]; then
            apt_install php8.3-mysql
        fi
		if systemctl is-active --quiet nginx.service; then
			hide_output "Restarting nginx..." sudo systemctl restart nginx.service
		else
			hide_output "Starting nginx..." sudo systemctl start nginx.service
		fi
        log_message "Fixed DB connection issue"
        echo -e "$GREEN Done$COL_RESET"
        
        # Installing other needed files
        echo
        echo -e "$CYAN => Installing email and utility tools : $COL_RESET"
        sleep 3

        apt_install sendmail mutt
        log_message "Installed email and utility tools"
        echo -e "$GREEN Done...$COL_RESET"
        sleep 3

        clear
        term_art_server
        # Installing Package to compile crypto currency
        echo
        echo -e "$CYAN => Installing Package to compile crypto currency $COL_RESET"
        sleep 3

		package_compile_crypto
		log_message "Compiled cryptocurrency packages"
		echo -e "$GREEN Done...$COL_RESET"

        # Generating Random Passwords
        password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        password2=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        AUTOGENERATED_PASS=$(pwgen -c -1 20)

        # Test Email
        echo
        echo -e "$CYAN => Testing to see if server emails are sent $COL_RESET"
        sleep 3

        if [[ "$root_email" != "" ]]; then
            echo $root_email | sudo tee --append ~/.email
            echo $root_email | sudo tee --append ~/.forward

            if [[ ("$send_email" == "y" || "$send_email" == "Y" || "$send_email" == "") ]]; then
                echo "This is a mail test for the SMTP Service." | sudo tee --append /tmp/email.message
                echo "You should receive this !" >> /tmp/email.message
                echo "" >> /tmp/email.message
                echo "Cheers" >> /tmp/email.message
                sudo sendmail -s "SMTP Testing" $root_email < /tmp/email.message
                sudo rm -f /tmp/email.message
                echo "Mail sent"
                log_message "Sent test email"
            fi
        fi
        echo -e "$GREEN Done...$COL_RESET"

        # Installing Fail2Ban & UFW
        echo
        echo -e "$CYAN => Some optional installs (Fail2Ban & UFW) $COL_RESET"
        sleep 3

        if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
            apt_install fail2ban
            sudo systemctl status fail2ban | sed -n "1,3p"
            log_message "Installed and started Fail2ban"
        fi

        apt_install ufw
        simple_hide_output sudo ufw default deny incoming
        simple_hide_output sudo ufw default allow outgoing
        simple_hide_output sudo ufw allow ssh
        simple_hide_output sudo ufw allow http
        simple_hide_output sudo ufw allow https
        simple_hide_output sudo ufw --force enable
        sleep 3
        sudo systemctl status ufw | sed -n "1,3p"
        log_message "Installed and configured UFW"
        echo -e "$GREEN Done...$COL_RESET"

        # Installing PhpMyAdmin
        echo
        echo -e "$CYAN => Installing phpMyAdmin $COL_RESET"
        sleep 3

        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password $rootpasswd" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/app-pass password $AUTOGENERATED_PASS" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/app-password-confirm password $AUTOGENERATED_PASS" | sudo debconf-set-selections

        apt_install phpmyadmin
        log_message "Installed phpMyAdmin"
        echo -e "$GREEN Done...$COL_RESET"

        # Installing Yiimp
        echo
        echo -e "$CYAN => Installing Yiimp $COL_RESET"
        echo -e "$YELLOW >--> Grabbing yiimp from Github, building files and setting file structure.$COL_RESET "
        sleep 3

        # Generating Random Password for stratum
        blckntifypass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        # Download Version of Yiimp and stratum
        cd ~
        if [[ ("$yiimpver" == "1" || "$yiimpver" == "") ]]; then
            hide_output sudo git clone $githubrepoKudaraidee
        elif [[ "$yiimpver" == "2" ]]; then
            hide_output sudo git clone $githubyiimptpruvot
        elif [[ "$yiimpver" == "3" ]]; then
            hide_output sudo git clone $githubrepoAfinielTech
        elif [[ "$yiimpver" == "4" ]]; then
            hide_output sudo git clone $githubrepoAfiniel -b next
        elif [[ "$yiimpver" == "5" ]]; then
            hide_output sudo git clone $githubrepoSabiasQue
        elif [[ "$yiimpver" == "6" ]]; then
            hide_output sudo git clone $githubrepoTpfuemp
        else
            hide_output sudo git clone $githubrepoTpfuemp
        fi

        hide_output sudo git clone $githubstratum
        log_message "Cloned Yiimp and stratum repositories"

        # Compile Blocknotify
        cd ${absolutepath}/stratum/blocknotify
        sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
        hide_output sudo make
        log_message "Compiled blocknotify"
        sleep 1

        # Compile iniparser
        cd ${absolutepath}/yiimp/stratum/iniparser
        hide_output sudo make
        log_message "Compiled iniparser"
        sleep 1

		# Compile Stratum
		cd ${absolutepath}/yiimp/stratum

		# Detection system
		ARCH=$(dpkg --print-architecture)
		if [ "$ARCH" = "arm64" ]; then
			sudo chmod +x ${absolutepath}/${nameofinstall}/utils/stratum_arm.sh
			sudo ${absolutepath}/${nameofinstall}/utils/stratum_arm.sh ${absolutepath}/yiimp/stratum
		else
			cd ${absolutepath}/yiimp/stratum
			sudo make
		fi
		sleep 1

		# Modify Files (Admin_panel), Wallets path, Web Path footer
		sudo sed -i 's/myadmin/'$admin_panel'/' ${absolutepath}/yiimp/web/yaamp/modules/site/SiteController.php
		sudo sed -i 's/AdminRights/'$admin_panel'/' ${absolutepath}/yiimp/web/yaamp/modules/site/SiteController.php
		sudo sed -i 's@domain:@<?=YAAMP_SITE_URL ?>:@' ${absolutepath}/yiimp/web/yaamp/modules/site/index.php
		sudo sed -i 's@domain@<?=YAAMP_SITE_NAME ?>@' ${absolutepath}/yiimp/web/yaamp/modules/site/index.php
		if [[ -f ${absolutepath}/yiimp/web/yaamp/modules/site/memcached.php ]]; then
			sudo sed -i 's@(real)@@' ${absolutepath}/yiimp/web/yaamp/modules/site/memcached.php
		fi
		if [[ -f ${absolutepath}/yiimp/web/yaamp/modules/site/coin_form.php ]]; then
			sudo sed -i 's@/home/yiimp-data/yiimp/site/stratum/blocknotify@blocknotify.sh@' ${absolutepath}/yiimp/web/yaamp/modules/site/coin_form.php
			sudo sed -i 's@/home/crypto-data/yiimp/site/stratum/blocknotify@blocknotify.sh@' ${absolutepath}/yiimp/web/yaamp/modules/site/coin_form.php
			sudo sed -i 's@".YAAMP_STRATUM_URL.":@@' ${absolutepath}/yiimp/web/yaamp/modules/site/coin_form.php
		fi
		if [[ -f ${absolutepath}/yiimp/web/index.php ]]; then
			# Supprimer toute ligne contenant require_once avec serverconfig.php
			sudo sed -i '/require_once.*serverconfig\.php/d' ${absolutepath}/yiimp/web/index.php
			# Insérer require_once('serverconfig.php'); après <?php
			sudo sed -i '/^<?php/a require_once('\''serverconfig.php'\'');' ${absolutepath}/yiimp/web/index.php
		fi

        log_message "Modified Yiimp configuration files"

        URLREPLACEWEBVAR=/var/web
        URLSHYIIMPDATA=/home/yiimp-data/yiimp/site/web
        URLSHCRYPTODATA=/home/crypto-data/yiimp/site/web

        cd ${absolutepath}/yiimp/web/yaamp/
        sudo find ./ -type f -exec sed -i 's@'${URLSHYIIMPDATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
        sudo find ./ -type f -exec sed -i 's@'${URLSHCRYPTODATA}'@'${URLREPLACEWEBVAR}'@g' {} \;

        URLREPLACEWEBWAL=${absolutepath}/wallets/
        URLSCRYPTODATAWALLET=/home/crypto-data/wallets/
        URLSYIIMPDATAWALLET=/home/yiimp-data/wallets/

        sudo find ./ -type f -exec sed -i 's@'${URLSCRYPTODATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
        sudo find ./ -type f -exec sed -i 's@'${URLSYIIMPDATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
        log_message "Updated file paths in Yiimp"
 
        # Copy Files (Blocknotify, iniparser, Stratum, web)
        cd ${absolutepath}/yiimp
        sudo cp -r ${absolutepath}/yiimp/web/ /var/
        sudo mkdir -p /var/stratum
        sudo chgrp ${whoami} /var/stratum
        sudo chown ${whoami} /var/stratum
        cd ${absolutepath}/yiimp/stratum
        sudo cp -a config.sample/. /var/stratum/config/
		
		if [[ -d stratum ]]; then
			sudo cp -r stratum /var/stratum/
			log_message "Copied stratum directory to /var/stratum/"
		fi

        cd ${absolutepath}/yiimp
        sudo cp -r ${absolutepath}/stratum/blocknotify/blocknotify /usr/bin/
        sudo cp -r ${absolutepath}/stratum/blocknotify/blocknotify /var/stratum/
        sudo mkdir -p /etc/yiimp
        sudo chgrp ${whoami} /etc/yiimp
        sudo chown ${whoami} /etc/yiimp
        sudo mkdir -p /${absolutepath}/backup/
        sudo chgrp ${whoami} /${absolutepath}/backup
        sudo chown ${whoami} /${absolutepath}/backup
        log_message "Copied Yiimp and stratum files"

        echo '#!/usr/bin/env bash

        ROOTDIR=/var
        DIR=`pwd`

        cd "$ROOTDIR/web" && php yaamp/yiic.php "$@"

        cd $DIR' | sudo -E tee /bin/yiimp >/dev/null 2>&1
        sudo chmod +x /bin/yiimp

        # Fixing run.sh
        sudo rm -r /var/stratum/config/run.sh
        echo '#!/bin/bash
        cd /var/stratum/config/ && sudo bash run.sh $*' | sudo -E tee /var/stratum/run.sh >/dev/null 2>&1
        sudo chmod +x /var/stratum/run.sh
        sudo chgrp ${whoami} /var/stratum/run.sh
        sudo chown ${whoami} /var/stratum/run.sh
 
        echo '
        #!/bin/bash
        ulimit -n 10240
        ulimit -u 10240
        cd /var/stratum
        while true; do
            ./stratum /var/stratum/config/$1
            sleep 2
        done
        exec bash' | sudo -E tee /var/stratum/config/run.sh >/dev/null 2>&1
        sudo chmod +x /var/stratum/config/run.sh
        sudo chgrp ${whoami} /var/stratum/config/run.sh
        sudo chown ${whoami} /var/stratum/config/run.sh
        # sudo cp -r ${absolutepath}/${nameofinstall}/conf/yaamp.php /var/web/yaamp/core/functions
        log_message "Configured stratum run scripts"

        echo -e "$GREEN Done...$COL_RESET"

        # Update Timezone
        echo
        echo -e "$CYAN => Update default timezone. $COL_RESET"
        echo -e " Setting TimeZone to UTC...$COL_RESET"
        if [ ! -f /etc/timezone ]; then
            echo "Setting timezone to UTC."
            echo "Etc/UTC" | sudo tee /etc/timezone
            sudo systemctl restart rsyslog
        fi
        sudo systemctl status rsyslog | sed -n "1,3p"
        log_message "Set timezone to UTC"
        echo -e "$GREEN Done...$COL_RESET"

        # Creating webserver initial config file
        echo
        echo -e "$CYAN => Creating webserver initial config file $COL_RESET"

        nginxcustomconf "${server_name}" "${PHPVERSION}"

        # Adding user to group, creating dir structure, setting permissions
        sudo mkdir -p /var/www/$server_name/html

        if [[ ("$sub_domain" == "n" || "$sub_domain" == "N") ]]; then
            confnginxnotssl "${server_name}" "${PHPVERSION}"
            sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
            sudo ln -s /var/web /var/www/$server_name/html
			if systemctl is-active --quiet nginx.service; then
				hide_output "Restarting nginx..." sudo systemctl restart nginx.service
			else
				hide_output "Starting nginx..." sudo systemctl start nginx.service
			fi
			if systemctl is-active --quiet php${PHPVERSION}-fpm.service; then
				hide_output "Restarting php${PHPVERSION}-fpm..." sudo systemctl restart php${PHPVERSION}-fpm.service
			else
				hide_output "Starting php${PHPVERSION}-fpm..." sudo systemctl start php${PHPVERSION}-fpm.service
			fi
            log_message "Configured Nginx without subdomain"
            echo -e "$GREEN Done...$COL_RESET"

            if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then
                # Install SSL (without SubDomain)
                echo
                echo -e "Install Certbot and setting SSL (without SubDomain)"
                sleep 3
                apt_install certbot python3-certbot-nginx
                sudo certbot --nginx --email "$EMAIL" --agree-tos --no-eff-email -d "$server_name" -d www."$server_name"
                sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
				if systemctl is-active --quiet nginx.service; then
					hide_output "Restarting nginx..." sudo systemctl restart nginx.service
				else
					hide_output "Starting nginx..." sudo systemctl start nginx.service
				fi
				if systemctl is-active --quiet php${PHPVERSION}-fpm.service; then
					hide_output "Restarting php${PHPVERSION}-fpm..." sudo systemctl restart php${PHPVERSION}-fpm.service
				else
					hide_output "Starting php${PHPVERSION}-fpm..." sudo systemctl start php${PHPVERSION}-fpm.service
				fi
                log_message "Installed SSL without subdomain"
                echo -e "$GREEN Done...$COL_RESET"
            fi
        else
            confnginxnotsslsub "${server_name}" "${sub_domain}" "${PHPVERSION}"
            sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
            sudo ln -s /var/web /var/www/$server_name/html
			if systemctl is-active --quiet nginx.service; then
				hide_output "Restarting nginx..." sudo systemctl restart nginx.service
			else
				hide_output "Starting nginx..." sudo systemctl start nginx.service
			fi
			if systemctl is-active --quiet php${PHPVERSION}-fpm.service; then
				hide_output "Restarting php${PHPVERSION}-fpm..." sudo systemctl restart php${PHPVERSION}-fpm.service
			else
				hide_output "Starting php${PHPVERSION}-fpm..." sudo systemctl start php${PHPVERSION}-fpm.service
			fi
            log_message "Configured Nginx with subdomain"
            echo -e "$GREEN Done...$COL_RESET"
        
            if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then
                # Install SSL (with SubDomain)
                echo
                echo -e "Install Certbot and setting SSL (with SubDomain)"
                apt_install certbot python3-certbot-nginx
                sudo certbot --nginx --email "$EMAIL" --agree-tos --no-eff-email -d "$server_name" -d "$sub_domain.$server_name"
                sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
				if systemctl is-active --quiet nginx.service; then
					hide_output "Restarting nginx..." sudo systemctl restart nginx.service
				else
					hide_output "Starting nginx..." sudo systemctl start nginx.service
				fi
				if systemctl is-active --quiet php${PHPVERSION}-fpm.service; then
					hide_output "Restarting php${PHPVERSION}-fpm..." sudo systemctl restart php${PHPVERSION}-fpm.service
				else
					hide_output "Starting php${PHPVERSION}-fpm..." sudo systemctl start php${PHPVERSION}-fpm.service
				fi
                log_message "Installed SSL with subdomain"
                echo -e "$GREEN Done...$COL_RESET"
            fi
        fi

        # Config Database
        echo
        echo -e "$CYAN => Now for the database fun! $COL_RESET"
        sleep 3
        
        # Create database
        Q1="CREATE DATABASE IF NOT EXISTS yiimpfrontend;"
        Q2="GRANT ALL ON *.* TO 'panel'@'localhost' IDENTIFIED BY '$password';"
        Q3="FLUSH PRIVILEGES;"
        SQL="${Q1}${Q2}${Q3}"
        sudo mysql -u root -p="" -e "$SQL"

        # Create stratum user
        Q1="GRANT ALL ON *.* TO 'stratum'@'localhost' IDENTIFIED BY '$password2';"
        Q2="FLUSH PRIVILEGES;"
        SQL="${Q1}${Q2}"
        sudo mysql -u root -p="" -e "$SQL"  
        
        # Create my.cnf
        echo '[clienthost1]
        user=panel
        password='"${password}"'
        database=yiimpfrontend
        host=localhost
        [clienthost2]
        user=stratum
        password='"${password2}"'
        database=yiimpfrontend
        host=localhost
        [myphpadmin]
        user=phpmyadmin
        password='"${AUTOGENERATED_PASS}"'
        [mysql]
        user=root
        password='"${rootpasswd}"'' | sudo -E tee ~/.my.cnf >/dev/null 2>&1
        sudo chgrp ${whoami} ~/.my.cnf
        sudo chown ${whoami} ~/.my.cnf
        sudo chmod 0600 ~/.my.cnf
        log_message "Configured MySQL users and .my.cnf"

        # Create keys file
        getconfkeys "panel" "${password}"
        log_message "Created Yiimp keys file"
        echo -e "$GREEN Done...$COL_RESET"

        # Performing the SQL import
        echo
        echo -e "$CYAN => Database 'yiimpfrontend' and users 'panel' and 'stratum' created with password $password and $password2, will be saved for you $COL_RESET"
        sleep 3

        cd ~
        cd ${absolutepath}/${nameofinstall}/conf/db
        
        if [[ "$DISTRO" == "20" ]]; then
            sudo zcat 2023-05-28-yiimp.sql.gz | sudo mysql -u root -p=${rootpasswd} yiimpfrontend
            if [[ "$yiimpver" == "5" ]]; then
                echo -e "$YELLOW => Selected install $yiimpver more sql adding... $COL_RESET"
                sleep 5
                sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 28-05-2023-articles.sql
                sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 28-05-2023-article_ratings.sql
                sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 28-05-2023-article_comments.sql
                sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2023-02-20-coins.sql
            fi
        else
            sudo zcat 2023-05-28-yiimp.sql.gz | sudo mysql -u root -p=${rootpasswd} yiimpfrontend
            if [[ "$yiimpver" == "5" ]]; then
                echo -e "$YELLOW => Selected install $yiimpver more sql adding... $COL_RESET"
                sleep 5
                sudo mysql --defaults-group-suffix=host1 --force < 28-05-2023-articles.sql
                sudo mysql --defaults-group-suffix=host1 --force < 28-05-2023-article_ratings.sql
                sudo mysql --defaults-group-suffix=host1 --force < 28-05-2023-article_comments.sql
                sudo mysql --defaults-group-suffix=host1 --force < 2023-02-20-coins.sql
            fi
        fi
        log_message "Imported Yiimp SQL database"
        cd ~

        echo -e "$GREEN Done...$COL_RESET"

        # Generating a basic Yiimp serverconfig.php
        echo
        echo -e "$CYAN => Generating a basic Yiimp serverconfig.php $COL_RESET"
        sleep 3

        # Make config file
        getserverconfig "${password}" "${server_name}" "${EMAIL}" "${Public}" "${admin_panel}"

        if [[ "$yiimpver" == "5" ]]; then
            addmoreserverconfig5
        fi
        log_message "Generated Yiimp serverconfig.php"
        echo -e "$GREEN Done...$COL_RESET"

        # Updating stratum config files with database connection info
        echo
        echo -e "$CYAN => Updating stratum config files with database connection info. $COL_RESET"
        sleep 3

        cd /var/stratum/config
        sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
        if [[ ("$sub_domain" == "n" || "$sub_domain" == "N") ]]; then
            sudo sed -i 's/server = yaamp.com/server = '$server_name'/g' *.conf
        else
            sudo sed -i 's/server = yaamp.com/server = '$sub_domain.$server_name'/g' *.conf
        fi
        sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
        sudo sed -i 's/database = yaamp/database = yiimpfrontend/g' *.conf
        sudo sed -i 's/username = root/username = stratum/g' *.conf
        sudo sed -i 's/password = patofpaq/password = '$password2'/g' *.conf
        cd ~
        HOMESSHEXIST=~/.ssh
        if [[ -d "${HOMESSHEXIST}" ]]; then
            sudo ssh-keyscan github.com >> ~/.ssh/known_hosts >/dev/null 2>&1
        else
            sudo mkdir -p ~/.ssh/
            sudo chown -R $USER ~/.ssh >/dev/null 2>&1
            sudo ssh-keyscan github.com >> ~/.ssh/known_hosts >/dev/null 2>&1
            sudo ssh-keyscan github.com >> ~/known_hosts >/dev/null 2>&1
        fi
        log_message "Updated stratum configuration"
        echo -e "$GREEN Done...$COL_RESET"
        sleep 3

        # Wireguard support
        if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
            echo
            echo -e "$CYAN => Installing wireguard support.... $COL_RESET"
            sleep 3
            apt_install wireguard wireguard-tools
            (umask 077 && printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null)
            wg genkey | sudo tee -a /etc/wireguard/wg0.conf | wg pubkey | sudo tee /etc/wireguard/publickey
            sudo sed -i '$a Address = '$wg_ip'/24\nListenPort = 6121\n\n' /etc/wireguard/wg0.conf
            sudo sed -i '$a #[Peer]\n#PublicKey= Remotes_Public_Key\n#AllowedIPs = Remote_wg0_IP/32\n#Endpoint=Remote_Public_IP:6121\n' /etc/wireguard/wg0.conf
            sudo systemctl start wg-quick@wg0
            sudo systemctl enable wg-quick@wg0
            sudo ufw allow 6121
            log_message "Installed and configured WireGuard"
            echo -e "$GREEN Done...$COL_RESET"
            sleep 3
        fi
    fi

    # Install CoinBuild
    if [[ "$RESUME_MODE" == "true" ]]; then
        clear
        term_art_server
    fi

    echo
    echo -e "$CYAN => Installing CoinBuild $COL_RESET"
    sleep 3

    # Trap Ctrl+C to provide resume instructions
    trap 'echo -e "$YELLOW Installation interrupted. You can resume CoinBuild installation with: ./install.sh r $COL_RESET"; sudo rm -rf "$temp_dir" 2>/dev/null; exit 1' INT

    cd ${absolutepath}/${nameofinstall}
    STRATUMFILE=/var/stratum
    sudo git config --global url."https://github.com/".insteadOf git@github.com: >/dev/null 2>&1
    sudo git config --global url."https://".insteadOf git:// >/dev/null 2>&1
    sleep 2

    REPO="vaudois/daemoncoin-addport-stratum"
    LATESTVER=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r ".tag_name")

    temp_dir="$(mktemp -d)"
    sudo git clone -q git@github.com:${REPO%.git} "${temp_dir}" 2>> /var/log/yiimp/coinbuild_error.log && \
        cd "${temp_dir}" && \
        sudo git -c advice.detachedHead=false checkout -q tags/${LATESTVER} >> /var/log/yiimp/coinbuild_error.log 2>&1
    if [[ $? -ne 0 ]]; then
        echo
        echo -e "$RED Error: Failed to clone or checkout CoinBuild repository. Check your network connection or GitHub access.$COL_RESET"
        echo -e "$YELLOW You can resume the installation by running: ./install.sh r $COL_RESET"
        sudo rm -rf "$temp_dir"
        log_message "Failed to clone CoinBuild repository"
        sleep 3
    fi

    FILEINSTALLEXIST="${temp_dir}/install.sh"
    if [[ -f "$FILEINSTALLEXIST" ]]; then
        sudo chown -R "$USER" "${temp_dir}" >/dev/null 2>&1
        sleep 1
        cd "${temp_dir}"
        sudo find . -type f -name "*.sh" -exec chmod -R +x {} \; >/dev/null 2>&1
        sleep 1
        if ! ./install.sh "${temp_dir}" "${STRATUMFILE}" "${DISTRO}" >> /var/log/yiimp/coinbuild_error.log 2>&1; then
            echo
            echo -e "$RED Error: CoinBuild installation failed.$COL_RESET"
            echo -e "$YELLOW You can resume the installation by running: ./install.sh r $COL_RESET"
            sudo rm -rf "$temp_dir"
            log_message "CoinBuild installation script failed"
            sleep 3
        fi
        sudo rm -rf "$temp_dir"
        log_message "Installed CoinBuild"
    else
        echo
        echo -e "$RED Error: CoinBuild install.sh not found in repository.$COL_RESET"
        echo -e "$YELLOW You can resume the installation by running: ./install.sh r $COL_RESET"
        sudo rm -rf "$temp_dir"
        log_message "CoinBuild install.sh not found"
        sleep 3
    fi

    # Remove trap after CoinBuild
    trap - INT

    # Remove parameter file after successful installation
   # sudo rm -f "${absolutepath}/${installtoserver}/resume/install_params.conf" >/dev/null 2>&1
    log_message "Removed installation parameters file"

    clear
    term_art_server

    # Final Directory permissions
    echo
    echo -e "$CYAN => Final Directory permissions $COL_RESET"
    sleep 3

    echo '[clienthost1]
    user=panel
    database=yiimpfrontend
    password='"${password}"'
    host=localhost
    [clienthost2]
    user=stratum
    database=yiimpfrontend
    password='"${password2}"'
    host=localhost
    [myphpadmin]
    user=phpmyadmin
    password='"${AUTOGENERATED_PASS}"'
    [mysql]
    user=root
    password='"${rootpasswd}"'' | sudo -E tee ${absolutepath}/${installtoserver}/conf/server.conf >/dev/null 2>&1
    sudo chgrp ${whoami} ${absolutepath}/${installtoserver}/conf/server.conf
    sudo chown ${whoami} ${absolutepath}/${installtoserver}/conf/server.conf
    sudo chmod 0600 ${absolutepath}/${installtoserver}/conf/server.conf
    log_message "Created server.conf"

    echo 'STORAGE_USER='"${absolutepath}"'
    STORAGE_SITE=/var/web
    PUBLIC_IP='"${PUBLIC_IP}"'
    PUBLIC_IPV6='"${PUBLIC_IPV6}"'
    DISTRO='"${DISTRO}"'
    PRIVATE_IP='"${PRIVATE_IP}"'
    CRONS=/var/web/crons
    LOG_DIR=/var/log/yiimp
    PATH_STRATUM='"${STRATUMFILE}"'
    ' | sudo -E tee /etc/serveryiimp.conf >/dev/null 2>&1
    sudo chgrp ${whoami} /etc/serveryiimp.conf
    sudo chown ${whoami} /etc/serveryiimp.conf
    log_message "Created serveryiimp.conf"

    updatemotdrebootrequired
    updatemotdupdatesavailable
    updatemotdhweeol
    updatemotdfsckatreboot

    if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
        # Saving data for possible remote stratum setups
        VPNSERVER=$(curl -q http://ifconfig.me)
        echo "export yiimpver=$yiimpver" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
        echo "export blckntifypass=$blckntifypass" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
        echo "export server_name=$(hostname -f)" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
        WGPUBKEY=$(sudo cat /etc/wireguard/publickey)
        echo "export MYSQLIP=$wg_ip" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
        echo "export VPNPUBBKEY=$WGPUBKEY" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
    else
        echo "export MYSQLIP=$server_name" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
        echo "export VPNPUBBKEY=" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
    fi

    whoami=$(whoami)
    sudo usermod -aG www-data $whoami
    sudo usermod -a -G www-data $whoami

    sudo find /var/web -type d -exec chmod 775 {} +
    sudo find /var/web -type f -exec chmod 664 {} +
    sudo chgrp www-data /var/web -R
    sudo chmod g+w /var/web -R

    sudo chgrp www-data /var/stratum -R
    sudo chmod 775 /var/stratum

    sudo mkdir -p /var/yiimp/sauv/ >/dev/null 2>&1
    sudo chgrp ${whoami} /var/yiimp/sauv
    sudo chown ${whoami} /var/yiimp/sauv
    sudo chgrp www-data /var/yiimp -R
    sudo chmod 775 /var/yiimp -R

    sudo rm -r /etc/update-motd.d/
    sudo mkdir /etc/update-motd.d/ >/dev/null 2>&1
    sudo touch /etc/update-motd.d/00-header ; sudo touch /etc/update-motd.d/10-sysinfo ; sudo touch /etc/update-motd.d/90-footer ; sudo touch /etc/update-motd.d/91-contract-ua-esm-status.dpkg-dist
    sudo chmod +x /etc/update-motd.d/*
    sudo cp -r ${absolutepath}/${nameofinstall}/conf/update-motd.d/00-header /etc/update-motd.d/
    sudo cp -r ${absolutepath}/${nameofinstall}/conf/update-motd.d/10-sysinfo /etc/update-motd.d/
    sudo cp -r ${absolutepath}/${nameofinstall}/conf/update-motd.d/90-footer /etc/update-motd.d/
    sudo cp -r ${absolutepath}/${nameofinstall}/conf/update-motd.d/91-contract-ua-esm-status.dpkg-dist /etc/update-motd.d/
    
    sudo cp -r ${absolutepath}/${nameofinstall}/conf/screens /usr/bin/
    sudo chmod +x /usr/bin/screens
    
    sudo mkdir -p /var/web/crons/ >/dev/null 2>&1
    sudo chgrp ${whoami} /var/web/crons
    sudo chown ${whoami} /var/web/crons
    sudo cp -r ${absolutepath}/${nameofinstall}/utils/main.sh /var/web/crons/
    sudo chmod +x /var/web/crons/main.sh
    sudo cp -r ${absolutepath}/${nameofinstall}/utils/loop2.sh /var/web/crons/
    sudo chmod +x /var/web/crons/loop2.sh
    sudo cp -r ${absolutepath}/${nameofinstall}/utils/blocks.sh /var/web/crons/
    sudo chmod +x /var/web/crons/blocks.sh
    log_message "Set final directory permissions and copied MOTD/cron scripts"

    # Add to crontab screen-scrypt
    (crontab -l 2>/dev/null; echo "@reboot sleep 20 && /etc/screen-scrypt.sh") | crontab -
    log_message "Added screen-scrypt to crontab"

    # Fix error screen main
    sudo sed -i 's/"service $webserver start"/"sudo service $webserver start"/g' /var/web/yaamp/modules/thread/CronjobController.php
    sudo sed -i 's/"service nginx stop"/"sudo service nginx stop"/g' /var/web/yaamp/modules/thread/CronjobController.php
    log_message "Fixed CronjobController.php for service commands"

    # Fix error screen main "backup sql frontend"
    sudo sed -i "s|/root/backup|/var/yiimp/sauv|g" /var/web/yaamp/core/backend/system.php
    log_message "Fixed backup path in system.php"

    # Fix error phpmyadmin
    FILELIBPHPMYADMIN=/usr/share/phpmyadmin/libraries/sql.lib.php
    if [[ -f "${FILELIBPHPMYADMIN}" ]]; then
        sudo sed -i "s/|\s*\((count(\$analyzed_sql_results\['select_expr'\]\)/| (\1)/g" /usr/share/phpmyadmin/libraries/sql.lib.php
        log_message "Applied phpMyAdmin SQL fix"
    else
        log_message "phpMyAdmin SQL lib file not found, skipping fix"
    fi

    # Apply Yiimp fixes for PHP 8.x
    sudo sed -i "s|ExplorerController::createUrl|Yii::app()->createUrl|g" /var/web/yaamp/models/db_coinsModel.php
    log_message "Applied PHP 8.x fix for db_coinsModel.php"
    SEARCHLINECOINID="echo\sCUFHtml::openTag('fieldset',\sarray('class'=>'inlineLabels'));"
    INSERTLINESCOINID="echo\tCUFHtml::openTag('fieldset',\tarray('class'=>'inlineLabels'));\nif(empty(\$coin\->id))\t\$coin\->id\t=\tdbolist(\"SELECT\t(MAX(id)+1)\tFROM\tcoins\")[0]['(MAX(id)+1)'];"
	if [[ -f /var/web/yaamp/modules/site/coin_form.php ]]; then
		sudo sed -i "s#${SEARCHLINECOINID}#${INSERTLINESCOINID}#" /var/web/yaamp/modules/site/coin_form.php
	fi
    log_message "Applied PHP 8.x fix for coin_form.php"

    # Misc
    log_message "Starting miscellaneous cleanup and service configuration"

	cd ${absolutepath}/yiimp/stratum
	sudo make clean
	if [[ ! -f ${absolutepath}/yiimp/stratum/install.log ]]; then
		sudo rm ${absolutepath}/yiimp/stratum/install.log
	fi
	cd ${absolutepath}/stratum
	sudo make clean
	if [[ ! -f ${absolutepath}/stratum/install.log ]]; then
		sudo rm ${absolutepath}/stratum/install.log
	fi

	sudo mv -r ${absolutepath}/yiimp/stratum ${absolutepath}/stratum_${yiimpver}
	sudo chown ${whoami} ${absolutepath}/stratum_${yiimpver}
	sudo mv -r ${absolutepath}/yiimp/stratum ${absolutepath}/stratum_default
	sudo chown ${whoami} ${absolutepath}/stratum_default
    sudo rm -rf ${absolutepath}/yiimp
    sudo rm -rf ${absolutepath}/${nameofinstall}
    log_message "Removed temporary directories: yiimp, stratum, ${nameofinstall}"

    # Truncate Nginx logs instead of deleting
    sudo truncate -s 0 /var/log/nginx/*.log >/dev/null 2>&1
    log_message "Truncated Nginx logs"

    sudo update-alternatives --set php /usr/bin/php${PHPVERSION} >/dev/null 2>&1
    log_message "Set PHP version to ${PHPVERSION}"

    # Restart and verify services
    for service in cron mysql nginx php${PHPVERSION}-fpm; do
        sudo systemctl restart ${service}
        if sudo systemctl is-active --quiet ${service}; then
            log_message "Successfully restarted ${service}"
            sudo systemctl status ${service} | sed -n "1,3p"
        else
            log_message "Failed to restart ${service}"
            echo -e "$RED Failed to restart ${service}! Check logs for details.$COL_RESET"
        fi
    done

    # Set secure permissions
    sudo chmod 775 /var/web/yaamp/runtime >/dev/null 2>&1
    sudo chown www-data:www-data /var/web/yaamp/runtime >/dev/null 2>&1
    log_message "Set permissions for /var/web/yaamp/runtime"
    sudo chmod 775 /var/log/yiimp/debug.log >/dev/null 2>&1
    sudo chown www-data:www-data /var/log/yiimp/debug.log >/dev/null 2>&1
    log_message "Set permissions for /var/log/yiimp/debug.log"

    # Manage screens sessions
    SCREEN_SESSIONS=("main" "blocks" "debug" "loop2")
    for session in "${SCREEN_SESSIONS[@]}"; do
        if [[ -x /usr/bin/screens ]]; then
            sudo /usr/bin/screens restart ${session} >/dev/null 2>&1
            if screen -ls | grep -q "[0-9]\+\.${session}\s"; then
                log_message "Successfully restarted screens session: ${session}"
            else
                log_message "Failed to restart screens session: ${session}"
                echo -e "$RED Failed to restart screens session ${session}! Check /usr/bin/screens or session status.$COL_RESET"
            fi
        else
            log_message "Screens script not found or not executable at /usr/bin/screens"
            echo -e "$RED Screens script not found or not executable at /usr/bin/screens!$COL_RESET"
        fi
    done

	# Remove temporary swap file if created
	if [[ "$CREATED_SWAP" == "true" ]]; then
		sudo swapoff "$SWAP_FILE" >/dev/null 2>&1
		sudo rm -f "$SWAP_FILE" >/dev/null 2>&1
		log_message "Removed temporary swap file $SWAP_FILE"
	fi

    echo -e "$GREEN Done...$COL_RESET"
    log_message "Completed miscellaneous setup and service restarts"
    sleep 3

    echo
    install_end_message
    log_message "Displayed installation end message"

    cd ${absolutepath}
    cd ~
    log_message "Installation script completed"
    echo
