#!/bin/bash
################################################################################
# Original Author:   crombiecrunch
# Fork Author: manfromafar
# Current Author: Vaudois
#
# Program:
#   Install yiimp on Ubuntu 16.04/18.04 running Nginx, MariaDB, and php7.3
#   v0.5
# 
################################################################################

if [ -z "${TAG}" ]; then
	TAG=v0.5
fi

NPROC=$(nproc)

clear

	### Variable ###
	githubyiimptpruvot=https://github.com/tpruvot/yiimp.git
	githubrepoKudaraidee=https://github.com/Kudaraidee/yiimp.git
	githubrepoAfinielTech=https://github.com/Afiniel-tech/yiimp.git
	githubrepoAfiniel=https://github.com/afiniel/yiimp.git
	githubrepoSabiasQue=https://github.com/SabiasQueSpace/SQSYIIMPALTE.git
	
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

	#Add user group sudo + no password
	whoami=$(whoami)
	sudo usermod -aG sudo ${whoami}
	echo '# yiimp
	# It needs passwordless sudo functionality.
	'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
	' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

	#Copy needed files
	sudo cp -r conf/functions.sh /etc/
	sudo cp -r conf/screen-scrypt.sh /etc/
	sudo cp -r conf/editconf.py /usr/bin/
	sudo chmod +x /usr/bin/editconf.py
	sudo chmod +x /etc/screen-scrypt.sh

	source /etc/functions.sh
	source conf/prerequisite.sh
	sleep 3
	source conf/getip.sh
	source utils/packagecompil.sh

	clear	
	term_art_server

	# Update package and Upgrade Ubuntu
	echo
	echo -e "$CYAN => Updating system and installing required packages :$COL_RESET"
	sleep 3
        
	hide_output sudo apt -y update 
	hide_output sudo apt -y upgrade
	hide_output sudo apt -y autoremove
	apt_install dialog python3 python3-pip acl nano apt-transport-https
	apt_install figlet curl jq
	echo -e "$GREEN Done...$COL_RESET"

	echo 'PUBLIC_IP='"${PUBLIC_IP}"'
	PUBLIC_IPV6='"${PUBLIC_IPV6}"'
	DISTRO='"${DISTRO}"'
	PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee conf/pool.conf >/dev/null 2>&1

	term_art_server
	echo
	echo -e "$RED Make sure you double check before hitting enter! Only one shot at these! $COL_RESET"
	#read -e -p "Enter time zone (e.g. America/New_York) : " TIME
	read -e -p "Domain Name (no http:// or www. just : example.com or 185.22.24.26) : " server_name
	read -e -p "Enter subdomain from stratum connections miners (europe.example.com?) [y/N] : " sub_domain
	read -e -p "Enter support email (e.g. admin@example.com) : " EMAIL
	read -e -p "Set Pool to AutoExchange? i.e. mine any coin with BTC address? [y/N] : " BTC
	read -e -p "Please enter a new location for /site/adminRights this is to customize the Admin Panel entrance url (e.g. myAdminpanel) : " admin_panel
	read -e -p "Enter the Public IP of the system you will use to access the admin panel (http://www.whatsmyip.org/) : " Public
	read -e -p "Desired Yiimp install?(1=Kudaraidee or 2=tpruvot or 3=Afiniel-Tech 4= Afiniel 5= SabiasQue(beta)) [1 by default] : " yiimpver
	read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
	read -e -p "Install UFW and configure ports? [Y/n] : " UFW
	read -e -p "Install LetsEncrypt SSL? IMPORTANT! You MUST have your domain name pointed to this server prior to running the script!! [Y/n]: " ssl_install
	read -e -p "Install Wireguard for future remote stratums??? [y/N]: " wg_install
	if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
		read -e -p "Enter a Local Wireguard Private IP for this server (x.x.x.x): " wg_ip
	# curl -q http://ifconfig.me
	fi

	term_art_server
	echo -e "\n\n\n\n"
	echo -e "$RED You entered the following. If it's wrong CTRL-C now to start over $COL_RESET"
	echo "Domain Name:         $server_name"
	echo "Stratum Subdomain:   $sub_domain"
	echo "Support Email:       $EMAIL"
	echo "AutoExchange:        $BTC"
	echo "Panel Url:           $admin_panel"
	echo "IP Range for Admin:  $Public"
	echo "Yiimb Github choice: $yiimpver"
	echo "Install Fail2ban:    $install_fail2ban"
	echo "Install UFW:         $UFW"
	echo "Install SSL now:     $ssl_install"
	echo "Install wiregauard:  $wg_install"
	echo "Wireguard wg0 IP:    $wg_ip"

    read -e -p "Press ENTER to continue or CTRL-C to exit and start over" dummy
    echo -e "\n\n\n\n"

	term_art_server
	# Switch Aptitude
	echo
	echo -e "$CYAN Switching to Aptitude $COL_RESET"
	sleep 3
	apt_install aptitude
	echo -e "$GREEN Done...$COL_RESET $COL_RESET"

	# Installing Nginx
	echo
	echo -e "$CYAN => Installing Nginx server : $COL_RESET"
	sleep 3
    
	if [ -f /usr/sbin/apache2 ]; then
		echo -e "Removing apache..."
		hide_output apt-get -y purge apache2 apache2-*
		hide_output apt-get -y --purge autoremove
	fi

	apt_install nginx
	hide_output sudo rm /etc/nginx/sites-enabled/default
	hide_output sudo systemctl start nginx.service
	hide_output sudo systemctl enable nginx.service
	hide_output sudo systemctl start cron.service
	hide_output sudo systemctl enable cron.service
	sudo systemctl status nginx | sed -n "1,3p"
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

	# Installing Mariadb
	echo
	echo -e "$CYAN => Installing Mariadb Server : $COL_RESET"
	sleep 3

	# Create random password
	rootpasswd=$(openssl rand -base64 12)
	export DEBIAN_FRONTEND="noninteractive"
	apt_install mariadb-server
	hide_output sudo systemctl start mysql
	hide_output sudo systemctl enable mysql
	sleep 5
	sudo systemctl status mysql | sed -n "1,3p"
	echo -e "$GREEN Done...$COL_RESET"

	# Installing Installing php7.3
	echo
	echo -e "$CYAN => Installing php7.3 : $COL_RESET"
	sleep 3
    
	source conf/pool.conf
	if [ ! -f /etc/apt/sources.list.d/ondrej-php-bionic.list ]; then
		hide_output sudo add-apt-repository -y ppa:ondrej/php
	fi
		hide_output sudo apt -y update

	if [[ ("$DISTRO" == "16") ]]; then
		apt_install php7.3-fpm php7.3-opcache php7.3 php7.3-common php7.3-gd php7.3-mysql php7.3-imap php7.3-cli \
		php7.3-cgi php-pear php-auth imagemagick libruby php7.3-curl php7.3-intl php7.3-pspell mcrypt \
		php7.3-recode php7.3-sqlite3 php7.3-tidy php7.3-xmlrpc php7.3-xsl memcached php-memcache php-imagick php-gettext php7.3-zip php7.3-mbstring php7.3-memcache php7.3-memcached
	else
		apt_install php7.3-fpm php7.3-opcache php7.3 php7.3-common php7.3-gd php7.3-mysql php7.3-imap php7.3-cli
		apt_install php7.3-cgi php-pear imagemagick libruby php7.3-curl php7.3-intl php7.3-pspell mcrypt
		apt_install php7.3-recode php7.3-sqlite3 php7.3-tidy php7.3-xmlrpc php7.3-xsl memcached php-memcache php-imagick php7.3-zip php7.3-mbstring
		apt_install libpsl-dev libnghttp2-dev php7.3-memcache php7.3-memcached php-curl
	fi
	if [[ ("$DISTRO" == "18") ]]; then
		apt_install php-gettext
	fi

	sleep 5
	hide_output sudo systemctl start php7.3-fpm
	sudo systemctl status php7.3-fpm | sed -n "1,3p"

	echo -e "$GREEN Done...$COL_RESET"

	# fix CDbConnection failed to open the DB connection.
	echo
	echo -e "$CYAN => Fixing DBconnection issue $COL_RESET"
	apt_install php8.1-mysql
	echo
	hide_output service nginx restart

	echo -e "$GREEN Done$COL_RESET"
    
	# Installing other needed files
	echo
	echo -e "$CYAN => Installing other needed files : $COL_RESET"
	sleep 3

	apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev libldap2-dev libidn11-dev gnutls-dev \
	librtmp-dev sendmail mutt screen git
	apt_install pwgen -y
	
	echo -e "$GREEN Done...$COL_RESET"
	sleep 3

	# Installing Package to compile crypto currency
	echo
	echo -e "$CYAN => Installing Package to compile crypto currency $COL_RESET"

	sleep 3
	package_compile_crypto

	echo
	echo -e "$GREEN Done...$COL_RESET"

	# Generating Random Passwords
	password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
	password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
	AUTOGENERATED_PASS=`pwgen -c -1 20`

	# Test Email
	echo
	echo -e "$CYAN => Testing to see if server emails are sent $COL_RESET"
	sleep 3

	if [[ "$root_email" != "" ]]; then
		echo $root_email > sudo tee --append ~/.email
		echo $root_email > sudo tee --append ~/.forward

		if [[ ("$send_email" == "y" || "$send_email" == "Y" || "$send_email" == "") ]]; then
			echo "This is a mail test for the SMTP Service." > sudo tee --append /tmp/email.message
			echo "You should receive this !" >> sudo tee --append /tmp/email.message
			echo "" >> sudo tee --append /tmp/email.message
			echo "Cheers" >> sudo tee --append /tmp/email.message
			sudo sendmail -s "SMTP Testing" $root_email < sudo tee --append /tmp/email.message

			sudo rm -f /tmp/email.message
			echo "Mail sent"
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
	fi

    if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
		apt_install ufw

		hide_output sudo ufw default deny incoming
		hide_output sudo ufw default allow outgoing

		hide_output sudo ufw allow ssh
		hide_output sudo ufw allow http
		hide_output sudo ufw allow https

		hide_output sudo ufw --force enable
		sleep 3
		sudo systemctl status ufw | sed -n "1,3p"   
    fi

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
	
    echo -e "$GREEN Done...$COL_RESET"

	# Installing Yiimp
	echo
	echo -e "$CYAN => Installing Yiimp $COL_RESET"
	echo -e "$YELLOW Grabbing yiimp fron Github, building files and setting file structure.$COL_RESET "
	sleep 3

    # Generating Random Password for stratum
	blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

    # Download Version of Yiimp and stratum
    cd ~
    if [[ ("$yiimpver" == "1" || "$yiimpver" == "") ]];then
		cd ~
		hide_output sudo git clone $githubrepoKudaraidee
	elif [[ "$yiimpver" == "2" ]]; then
		cd ~
		hide_output sudo git clone $githubyiimptpruvot
		cd ~
	elif [[ "$yiimpver" == "3" ]]; then
		cd ~
		hide_output sudo git clone $githubrepoAfinielTech
	elif [[ "$yiimpver" == "4" ]]; then
		cd ~
		hide_output sudo git clone $githubrepoAfiniel -b next
	elif [[ "$yiimpver" == "5" ]]; then
		cd ~
		hide_output sudo git clone $githubrepoSabiasQue -b next
	fi

	cd ~
	hide_output sudo git clone $githubstratum

	# Compil Blocknotify
	cd ${absolutepath}/stratum/blocknotify
	sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
	hide_output sudo make

	# Compil iniparser
	cd ${absolutepath}/stratum/iniparser
	hide_output sudo make

	# Compil Stratum
	cd ${absolutepath}/stratum
	if [[ ("$BTC" == "y" || "$BTC" == "Y") ]]; then
		sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' ${absolutepath}/yiimp/stratum/Makefile
	fi
	hide_output sudo make

	# Modify Files (Admin_panel), Wallets path, Web Path footer
	sudo sed -i 's/myadmin/'$admin_panel'/' ${absolutepath}/yiimp/web/yaamp/modules/site/SiteController.php
	sleep 3
	sudo sed -i 's/AdminRights/'$admin_panel'/' ${absolutepath}/yiimp/web/yaamp/modules/site/SiteController.php
	sleep 3
	sudo sed -i 's@domain:@<?=YAAMP_SITE_URL ?>:@' ${absolutepath}/yiimp/web/yaamp/modules/site/index.php
	sleep 3
	sudo sed -i 's@domain@<?=YAAMP_SITE_NAME ?>@' ${absolutepath}/yiimp/web/yaamp/modules/site/index.php
	sleep 3

	URLREPLACEWEBVAR=/var/web
	URLSHYIIMPDATA=/home/yiimp-data/yiimp/site/web
	URLSHCRYPTODATA=/home/crypto-data/yiimp/site/web

	cd ${absolutepath}/yiimp/web/yaamp/
	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSHYIIMPDATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3

	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSHCRYPTODATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3

	cd ${absolutepath}/yiimp/web/yaamp/
	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSHCRYPTODATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3

	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSHYIIMPDATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3

	URLREPLACEWEBWAL=/home/wallets/
	URLSCRYPTODATAWALLET=/home/crypto-data/wallets/
	URLSYIIMPDATAWALLET=/home/yiimp-data/wallets/

	cd ${absolutepath}/yiimp/web/yaamp/
	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSCRYPTODATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
	sleep 3

	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSYIIMPDATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
	sleep 3

	cd ${absolutepath}/yiimp/web/yaamp/
	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSYIIMPDATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
	sleep 3

	sleep 3
	sudo find ./ -type f -exec sed -i 's@'${URLSCRYPTODATAWALLET}'@'${URLREPLACEWEBWAL}'@g' {} \;
	sleep 3

	# Copy Files (Blocknotify,iniparser,Stratum)
	cd ${absolutepath}/yiimp
	sudo cp -r ${absolutepath}/yiimp/web /var/
	sudo mkdir -p /var/stratum
	cd ${absolutepath}/stratum
	sudo cp -a config.sample/. /var/stratum/config
	sudo cp -r stratum /var/stratum
	sudo cp -r run.sh /var/stratum
	cd ${absolutepath}/yiimp
	sudo cp -r ${absolutepath}/yiimp/bin/. /bin/
	sudo cp -r ${absolutepath}/stratum/blocknotify/blocknotify /usr/bin/
	sudo cp -r ${absolutepath}/stratum/blocknotify/blocknotify /var/stratum/
	sudo mkdir -p /etc/yiimp
	sudo mkdir -p /${absolutepath}/backup/
	#fixing yiimp
	sudo sed -i "s|ROOTDIR=/data/yiimp|ROOTDIR=/var|g" /bin/yiimp
	#fixing run.sh
	sudo rm -r /var/stratum/config/run.sh
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
	sleep 2
	sudo cp -r ${absolutepath}/${nameofinstall}/conf/yaamp.php /var/web/yaamp/core/functions

    echo -e "$GREEN Done...$COL_RESET"

	# Update Timezone
	echo
	echo -e "$CYAN => Update default timezone. $COL_RESET"

	# Check if link file
	#sudo [ -L /etc/localtime ] &&  sudo unlink /etc/localtime
	# Update time zone
	#sudo ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
	#apt_install ntpdate
	# Write time to clock.
	#sudo hwclock -w
	#echo -e "$GREEN Done...$COL_RESET"

	echo -e " Setting TimeZone to UTC...$COL_RESET"
	if [ ! -f /etc/timezone ]; then
		echo "Setting timezone to UTC."
		echo "Etc/UTC" > sudo /etc/timezone
		sudo systemctl restart rsyslog
	fi
	sudo systemctl status rsyslog | sed -n "1,3p"

	echo -e "$GREEN Done...$COL_RESET"

	# Creating webserver initial config file
	echo
	echo -e "$CYAN => Creating webserver initial config file $COL_RESET"

	echo '
	#####################################################
	# Updated by Vaudois for crypto use
	#####################################################
	# favicon.ico
	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	# robots.txt
	location = /robots.txt {
		log_not_found off;
		access_log off;
	}

	# assets, media
	location ~* \.(?:css(\.map)?|js(\.map)?|jpe?g|png|gif|ico|cur|heic|webp|tiff?|mp3|m4a|aac|ogg|midi?|wav|mp4|mov|webm|mpe?g|avi|ogv|flv|wmv)$ {
		expires 7d;
		access_log off;
	}

	# svg, fonts
	location ~* \.(?:svgz?|ttf|ttc|otf|eot|woff2?)$ {
		add_header Access-Control-Allow-Origin "*";
		expires 7d;
		access_log off;
	}

	location ^~ /list-algos/ {
		deny all;
		access_log off;
		return 301 https://'"${server_name}"';
	}

	# gzip
	gzip on;
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
	' | sudo -E tee /etc/yiimp/nginxCustom.conf >/dev/null 2>&1

	# Adding user to group, creating dir structure, setting permissions
	sudo mkdir -p /var/www/$server_name/html

	if [[ ("$sub_domain" == "y" || "$sub_domain" == "Y") ]]; then
	echo '
	#####################################################
	# Updated by Vaudois for crypto use...
	#####################################################
	include /etc/nginx/blockuseragents.rules;
	server
	{
		if ($blockedagent)
		{
			return 403;
		}
		if ($request_method !~ ^(GET|HEAD|POST)$)
		{
			return 444;
		}
		listen 80;
		listen [::]:80;
		server_name '"${server_name}"';
		root "/var/www/'"${server_name}"'/html/web";
		index index.html index.htm index.php;
		charset utf-8;
	
		location /
		{
			try_files $uri $uri/ /index.php?$args;
		}
		location @rewrite
		{
			rewrite ^/(.*)$ /index.php?r=$1;
		}

		access_log /var/log/nginx/'"${server_name}"'.app-access.log;
		error_log /var/log/nginx/'"${server_name}"'.app-error.log;
	
		# allow larger file uploads and longer script runtimes
		client_body_buffer_size  50k;
		client_header_buffer_size 50k;
		client_max_body_size 50k;
		large_client_header_buffers 2 50k;
		sendfile off;
	
		location ~ ^/index\.php$
		{
			fastcgi_split_path_info ^(.+\.php)(/.+)$;
			fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
			fastcgi_index index.php;
			include fastcgi_params;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			fastcgi_intercept_errors off;
			fastcgi_buffer_size 16k;
			fastcgi_buffers 4 16k;
			fastcgi_connect_timeout 300;
			fastcgi_send_timeout 300;
			fastcgi_read_timeout 300;
			try_files $uri $uri/ =404;
		}
		location ~ \.php$
		{
			return 404;
		}
		location ~ \.sh
		{
			return 404;
		}
		location ~ /\.ht
		{
			deny all;
		}
		location ~ /.well-known
		{
			allow all;
		}
		location /phpmyadmin
		{
			root /usr/share/;
			index index.php;
			try_files $uri $uri/ =404;
			location ~ ^/phpmyadmin/(doc|sql|setup)/
			{
				deny all;
			}
			location ~ /phpmyadmin/(.+\.php)$
			{
				fastcgi_pass unix:/run/php/php7.3-fpm.sock;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				include fastcgi_params;
				include snippets/fastcgi-php.conf;
			}
		}
		# additional config
		include /etc/yiimp/nginxCustom.conf;
    }' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1
	
	sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
	sudo ln -s /var/web /var/www/$server_name/html
	hide_output sudo systemctl reload php7.3-fpm.service
	hide_output sudo systemctl restart nginx.service
	echo -e "$GREEN Done...$COL_RESET"
    	
    if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then

		# Install SSL (with SubDomain)
		echo
		echo -e "Install LetsEncrypt and setting SSL (with SubDomain)"
		
		apt_install letsencrypt
		sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name"
		sudo rm /etc/nginx/sites-available/$server_name.conf
		sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

		# I am SSL Man!
		echo '
		#####################################################
		# Updated by Vaudois for crypto use...
		#####################################################
		include /etc/nginx/blockuseragents.rules;
		server
		{
			if ($blockedagent)
			{
				return 403;
			}
			if ($request_method !~ ^(GET|HEAD|POST)$)
			{
				return 444;
			}
			listen 80;
			listen [::]:80;
			server_name '"${server_name}"';

			# enforce https
			return 301 https://$server_name$request_uri;
		}
		server
		{
			if ($blockedagent)
			{
				return 403;
			}
			if ($request_method !~ ^(GET|HEAD|POST)$)
			{
				return 444;
			}
			listen 443 ssl http2;
			listen [::]:443 ssl http2;
			server_name '"${server_name}"';
			root /var/www/'"${server_name}"'/html/web;
			index index.php;
			access_log /var/log/nginx/'"${server_name}"'.app-access.log;
			error_log  /var/log/nginx/'"${server_name}"'.app-error.log;

			# allow larger file uploads and longer script runtimes
			client_body_buffer_size  50k;
			client_header_buffer_size 50k;
			client_max_body_size 50k;
			large_client_header_buffers 2 50k;
			sendfile off;

			# strengthen ssl security
			ssl_certificate /etc/letsencrypt/live/'"${server_name}"'/fullchain.pem;
			ssl_certificate_key /etc/letsencrypt/live/'"${server_name}"'/privkey.pem;
			ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
			ssl_prefer_server_ciphers on;
			ssl_session_cache shared:SSL:10m;
			ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
			ssl_dhparam /etc/ssl/certs/dhparam.pem;
			
			# Add headers to serve security related headers
			add_header Strict-Transport-Security "max-age=15768000; preload;";
			add_header X-Content-Type-Options nosniff;
			add_header X-XSS-Protection "1; mode=block";
			add_header X-Robots-Tag none;
			add_header Content-Security-Policy "frame-ancestors 'self'";
			location /
			{
				try_files $uri $uri/ /index.php?$args;
			}
			location @rewrite
			{
				rewrite ^/(.*)$ /index.php?r=$1;
			}
			location ~ ^/index\.php$
			{
				fastcgi_split_path_info ^(.+\.php)(/.+)$;
				fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
				fastcgi_index index.php;
				include fastcgi_params;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				fastcgi_intercept_errors off;
				fastcgi_buffer_size 16k;
				fastcgi_buffers 4 16k;
				fastcgi_connect_timeout 300;
				fastcgi_send_timeout 300;
				fastcgi_read_timeout 300;
				include /etc/nginx/fastcgi_params;
				try_files $uri $uri/ =404;
			}
			location ~ \.php$
			{
				return 404;
			}
			location ~ \.sh
			{
				return 404;
			}
			location ~ /\.ht
			{
				deny all;
			}
			location /phpmyadmin
			{
				root /usr/share/;
				index index.php;
				try_files $uri $uri/ =404;
				location ~ ^/phpmyadmin/(doc|sql|setup)/
				{
					deny all;
				}
				location ~ /phpmyadmin/(.+\.php)$
				{
					fastcgi_pass unix:/run/php/php7.3-fpm.sock;
					fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
					include fastcgi_params;
					include snippets/fastcgi-php.conf;
				}
			}
			# additional config
			include /etc/yiimp/nginxCustom.conf;
		}' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1
	fi

	hide_output sudo systemctl reload php7.3-fpm.service
	hide_output sudo systemctl restart nginx.service
	echo -e "$GREEN Done...$COL_RESET"

	else

		echo '
		#####################################################
		# Updated by Vaudois for crypto use...
		#####################################################
		include /etc/nginx/blockuseragents.rules;
		server
		{
			if ($blockedagent)
			{
				return 403;
			}
			if ($request_method !~ ^(GET|HEAD|POST)$)
			{
				return 444;
			}
			listen 80;
			listen [::]:80;
			server_name '"${server_name}"' www.'"${server_name}"';
			root "/var/www/'"${server_name}"'/html/web";
			index index.html index.htm index.php;
			charset utf-8;
			location /
			{
				try_files $uri $uri/ /index.php?$args;
			}
			location @rewrite
			{
				rewrite ^/(.*)$ /index.php?r=$1;
			}
		
			access_log /var/log/nginx/'"${server_name}"'.app-access.log;
			error_log /var/log/nginx/'"${server_name}"'.app-error.log;
		
			# allow larger file uploads and longer script runtimes
			client_body_buffer_size  50k;
			client_header_buffer_size 50k;
			client_max_body_size 50k;
			large_client_header_buffers 2 50k;
			sendfile off;
			location ~ ^/index\.php$
			{
				fastcgi_split_path_info ^(.+\.php)(/.+)$;
				fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
				fastcgi_index index.php;
				include fastcgi_params;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				fastcgi_intercept_errors off;
				fastcgi_buffer_size 16k;
				fastcgi_buffers 4 16k;
				fastcgi_connect_timeout 300;
				fastcgi_send_timeout 300;
				fastcgi_read_timeout 300;
				try_files $uri $uri/ =404;
			}
			location ~ \.php$
			{
				return 404;
			}
			location ~ \.sh
			{
				return 404;
			}
			location ~ /\.ht
			{
				deny all;
			}
			location ~ /.well-known
			{
				allow all;
			}
			location /phpmyadmin
			{
				root /usr/share/;
				index index.php;
				try_files $uri $uri/ =404;
				location ~ ^/phpmyadmin/(doc|sql|setup)/
				{
					deny all;
				}
				location ~ /phpmyadmin/(.+\.php)$
				{
				fastcgi_pass unix:/run/php/php7.3-fpm.sock;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				include fastcgi_params;
				include snippets/fastcgi-php.conf;
				}
			}
			# additional config
			include /etc/yiimp/nginxCustom.conf;
		}' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

		sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
		sudo ln -s /var/web /var/www/$server_name/html
		hide_output sudo systemctl reload php7.3-fpm.service
		hide_output sudo systemctl restart nginx.service
		echo -e "$GREEN Done...$COL_RESET"

		if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then
		
			# Install SSL (without SubDomain)
			echo
			echo -e "Install LetsEncrypt and setting SSL (without SubDomain)"
			sleep 3
			
			apt_install letsencrypt
			sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name" -d www."$server_name"
			sudo rm /etc/nginx/sites-available/$server_name.conf
			sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
			# I am SSL Man!
			echo '
			#####################################################
			# Updated by Vaudois for crypto use...
			#####################################################
			include /etc/nginx/blockuseragents.rules;
			server
			{
				if ($blockedagent)
				{
					return 403;
				}
				if ($request_method !~ ^(GET|HEAD|POST)$)
				{
					return 444;
				}
				listen 80;
				listen [::]:80;
				server_name '"${server_name}"';
				# enforce https
				return 301 https://$server_name$request_uri;
			}

			server
			{
				if ($blockedagent)
				{
					return 403;
				}
				if ($request_method !~ ^(GET|HEAD|POST)$)
				{
					return 444;
				}
				listen 443 ssl http2;
				listen [::]:443 ssl http2;
				server_name '"${server_name}"' www.'"${server_name}"';
			
				root /var/www/'"${server_name}"'/html/web;
				index index.php;
			
				access_log /var/log/nginx/'"${server_name}"'.app-access.log;
				error_log  /var/log/nginx/'"${server_name}"'.app-error.log;
			
				# allow larger file uploads and longer script runtimes
				client_body_buffer_size  50k;
				client_header_buffer_size 50k;
				client_max_body_size 50k;
				large_client_header_buffers 2 50k;
				sendfile off;
				
				# strengthen ssl security
				ssl_certificate /etc/letsencrypt/live/'"${server_name}"'/fullchain.pem;
				ssl_certificate_key /etc/letsencrypt/live/'"${server_name}"'/privkey.pem;
				ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
				ssl_prefer_server_ciphers on;
				ssl_session_cache shared:SSL:10m;
				ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
				ssl_dhparam /etc/ssl/certs/dhparam.pem;
			
				# Add headers to serve security related headers
				add_header Strict-Transport-Security "max-age=15768000; preload;";
				add_header X-Content-Type-Options nosniff;
				add_header X-XSS-Protection "1; mode=block";
				add_header X-Robots-Tag none;
				add_header Content-Security-Policy "frame-ancestors 'self'";
				
				location /
				{
					try_files $uri $uri/ /index.php?$args;
				}
				location @rewrite
				{
					rewrite ^/(.*)$ /index.php?r=$1;
				}
				location ~ ^/index\.php$
				{
					fastcgi_split_path_info ^(.+\.php)(/.+)$;
					fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
					fastcgi_index index.php;
					include fastcgi_params;
					fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
					fastcgi_intercept_errors off;
					fastcgi_buffer_size 16k;
					fastcgi_buffers 4 16k;
					fastcgi_connect_timeout 300;
					fastcgi_send_timeout 300;
					fastcgi_read_timeout 300;
					include /etc/nginx/fastcgi_params;
					try_files $uri $uri/ =404;
				}
				location ~ \.php$
				{
					return 404;
				}
				location ~ \.sh
				{
					return 404;
				}
				location ~ /\.ht
				{
					deny all;
				}
					location /phpmyadmin
				{
					root /usr/share/;
					index index.php;
					try_files $uri $uri/ =404;
					location ~ ^/phpmyadmin/(doc|sql|setup)/
					{
						deny all;
					}
						location ~ /phpmyadmin/(.+\.php)$
					{
						fastcgi_pass unix:/run/php/php7.3-fpm.sock;
						fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
						include fastcgi_params;
						include snippets/fastcgi-php.conf;
					}
				}
				# additional config
				include /etc/yiimp/nginxCustom.conf;
			}
				
			' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

			echo -e "$GREEN Done...$COL_RESET"

		fi

		hide_output sudo systemctl reload php7.3-fpm.service
		hide_output sudo systemctl restart nginx.service
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
    
	#Create my.cnf

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
	sudo chmod 0600 ~/.my.cnf

	# Create keys file
	echo '<?php
	/* Sample config file to put in /etc/yiimp/keys.php */
	define('"'"'YIIMP_MYSQLDUMP_USER'"'"', '"'"'panel'"'"');
	define('"'"'YIIMP_MYSQLDUMP_PASS'"'"', '"'"''"${password}"''"'"');

	// Exchange public keys (private keys are in a separate config file)
	define('"'"'EXCH_CRYPTOPIA_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_NOVA_SECRET'"'"','"'"''"'"');
	define('"'"'EXCH_ALCUREX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_ALTILLY_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_BIBOX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_BINANCE_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_BITTREX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_BITSTAMP_SECRET'"'"','"'"''"'"');
	define('"'"'EXCH_BLEUTRADE_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_BTER_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_CEXIO_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_CREX24_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_CCEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_COINMARKETS_PASS'"'"', '"'"''"'"');
	define('"'"'EXCH_CRYPTOHUB_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_CRYPTOWATCH_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_DELIONDEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_EMPOEX_SECKEY'"'"', '"'"''"'"');
	define('"'"'EXCH_ESCODEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_GATEIO_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_GRAVIEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_HITBTC_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_JUBI_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_KRAKEN_SECRET'"'"','"'"''"'"');
	define('"'"'EXCH_KUCOIN_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_LIVECOIN_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_POLONIEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_SHAPESHIFT_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_STOCKSEXCHANGE_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_SWIFTEX_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_TRADEOGRE_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_YOBIT_SECRET'"'"', '"'"''"'"');
	' | sudo -E tee /etc/yiimp/keys.php >/dev/null 2>&1

	echo -e "$GREEN Done...$COL_RESET"

	# Peforming the SQL import
	echo
	echo -e "$CYAN => Database 'yiimpfrontend' and users 'panel' and 'stratum' created with password $password and $password2, will be saved for you $COL_RESET"
	sleep 3

	cd ~
	cd ${absolutepath}/${nameofinstall}/conf/db
	
	if [[ ("$DISTRO" == "20") ]]; then
		# Import sql dump
		sudo zcat 2019-11-10-yiimp.sql.gz | sudo mysql -u root -p=${rootpasswd} yiimpfrontend

		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2015-07-01-accounts_hostaddr.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2015-07-15-coins_hasmasternodes.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2015-09-20-blocks_worker.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-02-17-payouts_errmsg.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-02-18-accounts_donation.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-02-23-shares_diff.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-03-26-markets.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-03-30-coins.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-04-03-accounts.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-04-24-market_history.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-04-27-settings.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-05-11-coins.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-05-15-benchmarks.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-05-23-bookmarks.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-06-01-notifications.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-06-04-bench_chips.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2016-11-23-coins.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-02-05-benchmarks.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-03-31-earnings_index.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-05-accounts_case_swaptime.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-06-payouts_coinid_memo.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-09-notifications.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-10-bookmarks.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2017-11-segwit.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2018-01-stratums_ports.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2018-02-coins_getinfo.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2018-09-22-workers.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2019-03-coins_thepool_life.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2020-06-03-blocks.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2022-10-29-blocks_effort.sql
		hide_output sudo mysql -u root -p=${rootpasswd} yiimpfrontend --force < 2022-10-14-shares_solo.sql
	else
		# Import sql dump
		sudo zcat 2019-11-10-yiimp.sql.gz | sudo mysql --defaults-group-suffix=host1

		# Oh the humanity!
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2015-07-01-accounts_hostaddr.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2015-07-15-coins_hasmasternodes.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2015-09-20-blocks_worker.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-02-17-payouts_errmsg.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-02-18-accounts_donation.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-02-23-shares_diff.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-03-26-markets.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-03-30-coins.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-04-03-accounts.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-04-24-market_history.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-04-27-settings.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-05-11-coins.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-05-15-benchmarks.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-05-23-bookmarks.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-06-01-notifications.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-06-04-bench_chips.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2016-11-23-coins.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-02-05-benchmarks.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-03-31-earnings_index.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-05-accounts_case_swaptime.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-06-payouts_coinid_memo.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-09-notifications.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-10-bookmarks.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2017-11-segwit.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2018-01-stratums_ports.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2018-02-coins_getinfo.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2018-09-22-workers.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2019-03-coins_thepool_life.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2020-06-03-blocks.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2022-10-29-blocks_effort.sql
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2022-10-14-shares_solo.sql
	fi
	cd ~

	echo -e "$GREEN Done...$COL_RESET"    

	# Generating a basic Yiimp serverconfig.php
	echo
	echo -e "$CYAN => Generating a basic Yiimp serverconfig.php $COL_RESET"
	sleep 3

	# Make config file
	echo '<?php
	ini_set('"'"'date.timezone'"'"', '"'"'UTC'"'"');
	define('"'"'YAAMP_LOGS'"'"', '"'"'/var/log/yiimp'"'"');
	define('"'"'YAAMP_HTDOCS'"'"', '"'"'/var/web'"'"');
	define('"'"'YIIMP_MYSQLDUMP_PATH'"'"', '"'"''"/var/yiimp/sauv"''"'"');
		
	define('"'"'YAAMP_BIN'"'"', '"'"'/var/bin'"'"');
	define('"'"'YAAMP_DBHOST'"'"', '"'"'localhost'"'"');
	define('"'"'YAAMP_DBNAME'"'"', '"'"'yiimpfrontend'"'"');
	define('"'"'YAAMP_DBUSER'"'"', '"'"'panel'"'"');
	define('"'"'YAAMP_DBPASSWORD'"'"', '"'"''"${password}"''"'"');
	define('"'"'YAAMP_PRODUCTION'"'"', true);
	define('"'"'YAAMP_RENTAL'"'"', false);
	define('"'"'YAAMP_LIMIT_ESTIMATE'"'"', false);
	define('"'"'YAAMP_FEES_SOLO'"'"', 1.0);
	define('"'"'YAAMP_FEES_MINING'"'"', 0.5);
	define('"'"'YAAMP_FEES_EXCHANGE'"'"', 2);
	define('"'"'YAAMP_FEES_RENTING'"'"', 2);
	define('"'"'YAAMP_TXFEE_RENTING_WD'"'"', 0.002);
	define('"'"'YAAMP_PAYMENTS_FREQ'"'"', 2*60*60);
	define('"'"'YAAMP_PAYMENTS_MINI'"'"', 0.001);
	define('"'"'YAAMP_ALLOW_EXCHANGE'"'"', false);
	define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', true);
	define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false);
	define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'USD'"'"'); // USD is main
	define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);
	define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');
	define('"'"'YAAMP_SITE_URL'"'"', '"'"''"${server_name}"''"'"');
	define('"'"'YAAMP_STRATUM_URL'"'"', YAAMP_SITE_URL); // change if your stratum server is on a different host
	define('"'"'YAAMP_SITE_NAME'"'"', '"'"'MyYiimpPool'"'"');
	define('"'"'YAAMP_ADMIN_EMAIL'"'"', '"'"''"${EMAIL}"''"'"');
	define('"'"'YAAMP_ADMIN_IP'"'"', '"'"''"${Public}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
	define('"'"'YAAMP_ADMIN_WEBCONSOLE'"'"', true);
	define('"'"'YAAMP_CREATE_NEW_COINS'"'"', false);
	define('"'"'YAAMP_NOTIFY_NEW_COINS'"'"', false);
	define('"'"'YAAMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');
	define('"'"'YAAMP_USE_NGINX'"'"', true);
	// Exchange public keys (private keys are in a separate config file)
	define('"'"'EXCH_CRYPTOPIA_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_POLONIEX_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_BITTREX_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_BLEUTRADE_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_BTER_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_YOBIT_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_CCEX_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_COINMARKETS_USER'"'"', '"'"''"'"');
	define('"'"'EXCH_COINMARKETS_PIN'"'"', '"'"''"'"');
	define('"'"'EXCH_BITSTAMP_ID'"'"','"'"''"'"');
	define('"'"'EXCH_BITSTAMP_KEY'"'"','"'"''"'"');
	define('"'"'EXCH_HITBTC_KEY'"'"','"'"''"'"');
	define('"'"'EXCH_KRAKEN_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_LIVECOIN_KEY'"'"', '"'"''"'"');
	define('"'"'EXCH_NOVA_KEY'"'"', '"'"''"'"');
	// Automatic withdraw to Yaamp btc wallet if btc balance > 0.3
	define('"'"'EXCH_AUTO_WITHDRAW'"'"', 0.3);
	// nicehash keys deposit account & amount to deposit at a time
	define('"'"'NICEHASH_API_KEY'"'"','"'"'f96c65a7-3d2f-4f3a-815c-cacf00674396'"'"');
	define('"'"'NICEHASH_API_ID'"'"','"'"'825979'"'"');
	define('"'"'NICEHASH_DEPOSIT'"'"','"'"'3ABoqBjeorjzbyHmGMppM62YLssUgJhtuf'"'"');
	define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');
	$cold_wallet_table = array(
	'"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"' => 0.10,
	);
	// Sample fixed pool fees
	$configFixedPoolFees = array(
		'"'"'zr5'"'"' => 2.0,
		'"'"'scrypt'"'"' => 20.0,
		'"'"'sha256'"'"' => 5.0,
	 );
	 
	 // Sample fixed pool fees solo
	$configFixedPoolFeesSolo = array(
		'"'"'zr5'"'"' => 2.0,
		'"'"'scrypt'"'"' => 20.0,
		'"'"'sha256'"'"' => 5.0,
		
	);
	// Sample custom stratum ports
	$configCustomPorts = array(
	//	'"'"'x11'"'"' => 7000,
	);
	// mBTC Coefs per algo (default is 1.0)
	$configAlgoNormCoef = array(
	//	'"'"'x11'"'"' => 5.0,
	);
	// #### More configs from Others Yiimp From Vaudois Github ####
	define('"'"'YAAMP_CONTACT_EMAIL'"'"', '"'"'mail@mail.com'"'"');
	define('"'"'YIIMP_VIEW_24H'"'"', false);
	// Google Analytics = '"'"''"'"' == disabled
	define('"'"'YAAMP_GOOGLE_ANALYTICS'"'"', '"'"''"'"');
	// Others server Stratums of inn Worl enter name Country ex: Europe
	define('"'"'YAAMP_THIS_SERVER_STRATUM'"'"', '"'"'europe'"'"');
	define('"'"'YAAMP_SERVERS_STRATUMS'"'"', array(
	'"'"'europe'"'"',
	));
	// use chat from CHATBRO.COM
	define('"'"'YAAMP_CHATBRO'"'"', true);
	define('"'"'YAAMP_CHATBRO_CONFIG_WEB'"'"', false);
	define('"'"'YAAMP_CHATBRO_ID'"'"', '"'"'YOUR-ID'"'"');
	// YAAMP_CHATBRO_CONFIG_WEB is false you can put the name of indefinite chats eg = chat1, new = chat2, new = chat3...
	define('"'"'YAAMP_CHATBRO_CUSTOM_NAME'"'"', '"'"'090822'"'"');
	// Bottom links social
	define('"'"'YAAMP_LINK_DISCORD'"'"', '"'"'LINK_DISCORD'"'"');
	define('"'"'YAAMP_LINK_TWITTER'"'"', true);
	define('"'"'YAAMP_LINK_MAILCONTACT'"'"', YAAMP_CONTACT_EMAIL);
	# TELEGRAM CONFIG BOT AND URL
	define('"'"'YAAMP_LINK_TELEGRAM'"'"', '"'"'+LINK_TELEGRAM'"'"');
	define('"'"'YAAMP_BOT_TOKEN_TELEGRAM'"'"', '"'"'BOT_TOKEN'"'"');
	define('"'"'YAAMP_CHAT_ID_TELEGRAM'"'"', '"'"'-CHAT_ID'"'"');
	define('"'"'YAAMP_LINK_GITHUB'"'"', false);
	// FOOTER Copyright add text or html info...
	define('"'"'YAAMP_FOOTER_COPY'"'"', '"'"''"'"');
	$date_promo_start 	= new DateTime('"'"'2022-09-09'"'"');
	$form_date_promo 	= $date_promo_start->format('"'"'Y M D H:i:s'"'"');
	$end_date_promo 	= '"'"'end 23:59'"'"';
	$msg_coin_up_promo 	= '"'"'For each block found, payment increase of 5%!'"'"'."\n\r"; 
	define('"'"'MESSAGE_BANNER_PROMO'"'"','"'"'EXTENDED PROMOTION: Fees 0% in Shared and SOLO'"'"'."\n\r".$msg_coin_up_promo.'"'"'Start '"'"' . $form_date_promo.'"'"' '"'"'.$end_date_promo);
	// define fee in % with COIN exp: '"'"'BTC'"'"' => 1.0,
	$configFixedPoolFeesCoin = array(
		//'"'"'JGC'"'"' => '"'"'0'"'"',
	);
	$configFixedPoolFeesCoinSolo = array(
		//'"'"'JGC'"'"' => '"'"'0'"'"',
	);
	// define REWARDS in % SWITH COIN FEE = 0, with COIN exp: '"'"'BTC'"'"' => 1,  <-- this rewards block + 1%
	$configFixedPoolRewardsCoin = array(
		//'"'"'JGC'"'"' => 5,
	);
	// COIN MESSAGE = RPC Error: error -8: dummy value must be set to "*", add COIN in line (coin_results.php)
	define('"'"'RPC_ERROR_8'"'"', array(
		'"'"'VTC'"'"',
		'"'"'LTC'"'"',
	));
	// COIN ERROR PAIMENTS = RPC Error (payment.php)
	// todo: enhance/detect payout_max from normal sendmany error
	define('"'"'RPC_ERROR_PAIMENT'"'"', array(
		'"'"'CURVE'"'"',
		'"'"'JGC'"'"',
	));' | sudo -E tee /var/web/serverconfig.php >/dev/null 2>&1

	echo -e "$GREEN Done...$COL_RESET"

	sleep 3

	# Generating a restart crons main loop2 blocks
	echo
	echo -e "$CYAN => Generating a restart crons = main, loop2, blocks $COL_RESET"
	sleep 3
    
	# Make crons main loop2 blocks

	echo '#!/bin/bash
	# Restart the pseudo cron screens...
	LOG_DIR=/var/log/yiimp
	WEB_DIR=/var/web
	screen -X -S main quit
	screen -X -S loop2 quit
	screen -X -S blocks quit
	screen -X -S debug quit
	screen -dmS main $WEB_DIR/main.sh
	screen -dmS loop2 $WEB_DIR/loop2.sh
	screen -dmS blocks $WEB_DIR/blocks.sh
	screen -dmS debug tail -f $LOG_DIR/debug.log' | sudo -E tee /bin/restartlg >/dev/null 2>&1
	sudo chmod +x /bin/restartlg

    echo -e "$GREEN Done...$COL_RESET"

	# Updating stratum config files with database connection info
	echo
	echo -e "$CYAN => Updating stratum config files with database connection info. $COL_RESET"
	sleep 3

	cd /var/stratum/config
	sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
	sudo sed -i 's/server = yaamp.com/server = '$server_name'/g' *.conf
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
	echo -e "$GREEN Done...$COL_RESET"
	sleep 3

	# Wireguard support
	if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
		echo
		echo -e "$CYAN => Installing wireguard support.... $COL_RESET"
		sleep 3
		hide_output sudo apt update -y
		hide_output sudo apt install wireguard-dkms wireguard-tools -y

		(umask 077 && printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null)
		wg genkey | sudo tee -a /etc/wireguard/wg0.conf | wg pubkey | sudo tee /etc/wireguard/publickey
		sudo sed -i '$a Address = '$wg_ip'/24\nListenPort = 6121\n\n' /etc/wireguard/wg0.conf
		sudo sed -i '$a #[Peer]\n#PublicKey= Remotes_Public_Key\n#AllowedIPs = Remote_wg0_IP/32\n#Endpoint=Remote_Public_IP:6121\n' /etc/wireguard/wg0.conf

		sudo systemctl start wg-quick@wg0
		sudo systemctl enable wg-quick@wg0

		sudo ufw allow 6121
		echo -e "$GREEN Done...$COL_RESET"
		sleep 3
	fi

	# Install CoinBuild
	cd ${absolutepath}/${nameofinstall}
	STRATUMFILE=/var/stratum
	sudo git config --global url."https://github.com/".insteadOf git@github.com: >/dev/null 2>&1
	sudo git config --global url."https://".insteadOf git:// >/dev/null 2>&1
	sleep 2

	REPO="vaudois/daemoncoin-addport-stratum"
	LATESTVER=$(curl -sL 'https://api.github.com/repos/${REPO}/releases/latest' | jq -r ".tag_name")

	temp_dir="$(mktemp -d)" && \
		sudo git clone -q git@github.com:${REPO%.git} "${temp_dir}" && \
			cd "${temp_dir}/" && \
				sudo git -c advice.detachedHead=false checkout -q tags/${LATESTVER} >/dev/null 2>&1
	sleep 1
	test $? -eq 0 ||
		{ 
			echo
			echo -e "$RED Error cloning repository. $COL_RESET";
			echo
			sudo rm -f $temp_dir
			exit 1;
		}

	FILEINSTALLEXIST="${temp_dir}/install.sh"
	if [ -f "$FILEINSTALLEXIST" ]; then
		sudo chown -R $USER ${temp_dir} >/dev/null 2>&1
		sleep 1
		cd ${temp_dir}
		sudo find . -type f -name "*.sh" -exec chmod -R +x {} \; >/dev/null 2>&1
		sleep 1
		./install.sh "${temp_dir}" "${STRATUMFILE}" "${DISTRO}"
		sudo rm -rf $temp_dir
	fi
	
	clear
	term_art_server

	# Final Directory permissions
	echo
	echo -e "$CYAN => Final Directory permissions $COL_RESET"
	sleep 3

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
	password='"${rootpasswd}"'' | sudo -E tee ${absolutepath}/${installtoserver}/conf/server.conf >/dev/null 2>&1
	sudo chmod 0600 ${absolutepath}/${installtoserver}/conf/server.conf


	echo "export MYSQLDB=yiimpfrontend" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export MYSQLUSER=stratum" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export MYSQLPASS=$stratumpass" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export BTC=$BTC" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export VPNSERVER=$VPNSERVER" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo -e "\n#\#SET THE VPN IP FOR THIS REMOTE STRATUM\n#\nexport VPNIP=??????" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	sudo chmod 400 ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf

	if [[ ("$wg_install" == "y" || "$wg_install" == "Y") ]]; then
	# Saving data for possible remote stratum setups (east coast / west coast / europe / asia ????)
	VPNSERVER=`curl -q http://ifconfig.me`
	echo "export yiimpver=$yiimpver" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export blckntifypass=$blckntifypass" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
	echo "export server_name=\$(hostname -f)" | sudo tee -a ${absolutepath}/${installtoserver}/conf/REMOTE_stratum.conf > /dev/null
		WGPUBKEY=`sudo cat /etc/wireguard/publickey`
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

	sudo mkdir /var/log/yiimp
	sudo touch /var/log/yiimp/debug.log
	sudo chgrp www-data /var/log/yiimp -R
	sudo chmod 775 /var/log/yiimp -R

	sudo chgrp www-data /var/stratum -R
	sudo chmod 775 /var/stratum

	sudo mkdir -p /var/yiimp/sauv
	sudo chgrp www-data /var/yiimp -R
	sudo chmod 775 /var/yiimp -R
    
	sudo cp -r ${absolutepath}/${nameofinstall}/utils/main.sh /var/web
	sudo chmod +x /var/web/main.sh
	sudo cp -r ${absolutepath}/${nameofinstall}/utils/loop2.sh /var/web
	sudo chmod +x /var/web/loop2.sh
	sudo cp -r ${absolutepath}/${nameofinstall}/utils/blocks.sh /var/web
	sudo chmod +x /var/web/blocks.sh

	#Add to contrab screen-scrypt
	(crontab -l 2>/dev/null; echo "@reboot sleep 20 && /etc/screen-scrypt.sh") | crontab -

	#fix error screen main
	sudo sed -i 's/service $webserver start/sudo service $webserver start/g' /var/web/yaamp/modules/thread/CronjobController.php
	sudo sed -i 's/service nginx stop/sudo service nginx stop/g' /var/web/yaamp/modules/thread/CronjobController.php

	#fix error screen main "backup sql frontend"
	sudo sed -i "s|/root/backup|/var/yiimp/sauv|g" /var/web/yaamp/core/backend/system.php

	#fix error phpmyadmin
	sudo sed -i "s/|\s*\((count(\$analyzed_sql_results\['select_expr'\]\)/| (\1)/g" /usr/share/phpmyadmin/libraries/sql.lib.php

	#Misc
	sudo rm -rf ${absolutepath}/yiimp
	sudo rm -rf ${absolutepath}/stratum
	sudo rm -rf ${absolutepath}/${nameofinstall}
	sudo rm -rf /var/log/nginx/*

	#Restart service
	#sudo update-alternatives --set php /usr/bin/php7.3
	#sleep 2
	#sudo service nginx restart
	#sleep 2
	#sudo service php7.3-fpm restart
	sleep 2
	sudo systemctl restart cron.service
	sleep 2
	sudo systemctl restart mysql
	sleep 2
	sudo systemctl status mysql | sed -n "1,3p"
	sudo systemctl restart nginx.service
	sleep 2
	sudo systemctl status nginx | sed -n "1,3p"
	sudo systemctl restart php7.3-fpm.service
	sleep 2
	sudo systemctl status php7.3-fpm | sed -n "1,3p"
	sudo restartlg
	sleep 2

	echo -e "$GREEN Done...$COL_RESET"
	sleep 3

	echo
	install_end_message

	echo ""
