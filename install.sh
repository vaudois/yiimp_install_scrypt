#!/bin/bash
################################################################################
# Original Author:   crombiecrunch
# Fork Author: manfromafar
# Current Author: Vaudois
#
# Program:
#   Install yiimp on Ubuntu 16.04/18.04 running Nginx, MariaDB, and php7.3
#   v0.1
# 
################################################################################
	
	### Variable ###
	githubyiimptpruvot=https://github.com/tpruvot/yiimp.git
	githubrepoKudaraidee=https://github.com/Kudaraidee/yiimp.git
	githubrepoAfinielTech=https://github.com/Afiniel-tech/yiimp.git
	githubrepoAfiniel=https://github.com/afiniel/yiimp
	
	absolutepath=$HOME

	output() {
    printf "\E[0;33;40m"
    echo $1
    printf "\E[0m"
    }

    displayErr() {
    echo
    echo $1;
    echo
    exit 1;
    }

    #Add user group sudo + no password
    whoami=`whoami`
    sudo usermod -aG sudo ${whoami}
    echo '# yiimp
    # It needs passwordless sudo functionality.
    '""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
    ' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1
    
    #Copy needed files
    sudo cp -r conf/functions.sh /etc/
    sudo cp -r conf/screen-scrypt.sh /etc/
    sudo cp -r conf/editconf.py /usr/bin/
	sudo cp -r utils/addport.sh /usr/bin/addport
	sudo chmod +x /usr/bin/addport
    sudo chmod +x /usr/bin/editconf.py
    sudo chmod +x /etc/screen-scrypt.sh

    source /etc/functions.sh
	source utils/packagecompil.sh
    clear	
	term_art

    # Update package and Upgrade Ubuntu
    echo
    echo
    echo -e "$CYAN => Updating system and installing required packages :$COL_RESET"
    echo 
    sleep 3
        
    hide_output sudo apt -y update 
    hide_output sudo apt -y upgrade
    hide_output sudo apt -y autoremove
    apt_install dialog python3 python3-pip acl nano apt-transport-https
    apt_install figlet
    echo -e "$GREEN Done...$COL_RESET"

    source conf/prerequisite.sh
    sleep 3
    source conf/getip.sh

    echo 'PUBLIC_IP='"${PUBLIC_IP}"'
    PUBLIC_IPV6='"${PUBLIC_IPV6}"'
    DISTRO='"${DISTRO}"'
    PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee conf/pool.conf >/dev/null 2>&1

    echo
    echo
    echo -e "$RED Make sure you double check before hitting enter! Only one shot at these! $COL_RESET"
    echo
    #read -e -p "Enter time zone (e.g. America/New_York) : " TIME
    read -e -p "Domain Name (no http:// or www. just : example.com or 185.22.24.26) : " server_name
    read -e -p "Enter subdomain from stratum connections miners (europe.example.com?) [y/N] : " sub_domain
    read -e -p "Enter support email (e.g. admin@example.com) : " EMAIL
    read -e -p "Set Pool to AutoExchange? i.e. mine any coin with BTC address? [y/N] : " BTC
    read -e -p "Please enter a new location for /site/adminRights this is to customize the Admin Panel entrance url (e.g. myAdminpanel) : " admin_panel
    read -e -p "Enter the Public IP of the system you will use to access the admin panel (http://www.whatsmyip.org/) : " Public
    read -e -p "Enter desired Yiimp GitHub (1=Kudaraidee or 2=tpruvot or 3=Afiniel-Tech 4= Afiniel) [1 by default] : " yiimpver
    read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
    read -e -p "Install UFW and configure ports? [Y/n] : " UFW
    read -e -p "Install LetsEncrypt SSL? IMPORTANT! You MUST have your domain name pointed to this server prior to running the script!! [Y/n]: " ssl_install
    
    
    # Switch Aptitude
    echo
    echo -e "$CYAN Switching to Aptitude $COL_RESET"
    echo 
    sleep 3
    apt_install aptitude
    echo -e "$GREEN Done...$COL_RESET $COL_RESET"


    # Installing Nginx
    echo
    echo
    echo -e "$CYAN => Installing Nginx server : $COL_RESET"
    echo
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
    echo
    echo -e "$GREEN Done...$COL_RESET"
	

    # Making Nginx a bit hard
    echo 'map $http_user_agent $blockedagent {
    default         0;
    ~*malicious     1;
    ~*bot           1;
    ~*backdoor      1;
    ~*crawler       1;
    ~*bandit        1;
    }
    ' | sudo -E tee /etc/nginx/blockuseragents.rules >/dev/null 2>&1
    
    
    # Installing Mariadb
    echo
    echo
    echo -e "$CYAN => Installing Mariadb Server : $COL_RESET"
    echo
    sleep 3
        
    # Create random password
    rootpasswd=$(openssl rand -base64 12)
    export DEBIAN_FRONTEND="noninteractive"
    apt_install mariadb-server
    hide_output sudo systemctl start mysql
    hide_output sudo systemctl enable mysql
    sudo systemctl status mysql | sed -n "1,3p"
    echo
    echo -e "$GREEN Done...$COL_RESET"

    
    # Installing Installing php7.3
    echo
    echo
    echo -e "$CYAN => Installing php7.3 : $COL_RESET"
    echo
    sleep 3
    
    source conf/pool.conf
    if [ ! -f /etc/apt/sources.list.d/ondrej-php-bionic.list ]; then
		hide_output sudo add-apt-repository -y ppa:ondrej/php
    fi
		hide_output sudo apt -y update

    if [[ ("$DISTRO" == "16") ]]; then
    apt_install php7.3-fpm php7.3-opcache php7.3 php7.3-common php7.3-gd php7.3-mysql php7.3-imap php7.3-cli \
    php7.3-cgi php-pear php-auth imagemagick libruby php7.3-curl php7.3-intl php7.3-pspell mcrypt\
    php7.3-recode php7.3-sqlite3 php7.3-tidy php7.3-xmlrpc php7.3-xsl memcached php-memcache php-imagick php-gettext php7.3-zip php7.3-mbstring php7.3-memcache
    else
    apt_install php7.3-fpm php7.3-opcache php7.3 php7.3-common php7.3-gd php7.3-mysql php7.3-imap php7.3-cli \
    php7.3-cgi php-pear imagemagick libruby php7.3-curl php7.3-intl php7.3-pspell mcrypt\
    php7.3-recode php7.3-sqlite3 php7.3-tidy php7.3-xmlrpc php7.3-xsl memcached php-memcache php-imagick php-gettext php7.3-zip php7.3-mbstring \
    libpsl-dev libnghttp2-dev php7.3-memcache
    fi
    sleep 5
		hide_output sudo systemctl start php7.3-fpm
    sudo systemctl status php7.3-fpm | sed -n "1,3p"
    echo
    echo -e "$GREEN Done...$COL_RESET"

    
    # Installing other needed files
    echo
    echo
    echo -e "$CYAN => Installing other needed files : $COL_RESET"
    echo
    sleep 3
    
    apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev libldap2-dev libidn11-dev gnutls-dev \
    librtmp-dev sendmail mutt screen git
    apt_install pwgen -y
    echo -e "$GREEN Done...$COL_RESET"
	sleep 3

    # Installing Package to compile crypto currency
    echo
    echo
    echo -e "$CYAN => Installing Package to compile crypto currency $COL_RESET"
    echo

	sleep 3
	package_compile_crypto       

	sleep 3
	package_compile_coin
	
	sleep 3
	package_daemonbuilder

	echo
	echo -e "$GREEN Done...$COL_RESET"

    # Generating Random Passwords
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    AUTOGENERATED_PASS=`pwgen -c -1 20`
    
    
    # Test Email
    echo
    echo
    echo -e "$CYAN => Testing to see if server emails are sent $COL_RESET"
    echo
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
    echo
    echo -e "$CYAN => Some optional installs (Fail2Ban & UFW) $COL_RESET"
    echo
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
    sudo systemctl status ufw | sed -n "1,3p"   
    fi

    echo
    echo -e "$GREEN Done...$COL_RESET"

    
    # Installing PhpMyAdmin
    echo
    echo
    echo -e "$CYAN => Installing phpMyAdmin $COL_RESET"
    echo
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
    echo
    echo -e "$CYAN => Installing Yiimp $COL_RESET"
    echo
    echo -e "Grabbing yiimp fron Github, building files and setting file structure."
    echo
    sleep 3
    

    # Generating Random Password for stratum
    blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    
    # Compil Blocknotify
    cd ~
    if [[ ("$yiimpver" == "1" || "$yiimpver" == "") ]];then
		cd ~
		hide_output git clone $githubrepoKudaraidee
    elif [[ "$yiimpver" == "2" ]]; then
		cd ~
		hide_output git clone $githubyiimptpruvot
		cd ~
	elif [[ "$yiimpver" == "3" ]]; then
		cd ~
		hide_output git clone $githubrepoAfinielTech
	elif [[ "$yiimpver" == "4" ]]; then
		cd ~
		hide_output git clone $githubrepoAfiniel -b next
	fi

    cd $HOME/yiimp/blocknotify
    sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
    hide_output sudo make
    
    # Compil iniparser
    cd $HOME/yiimp/stratum/iniparser
    hide_output sudo make
    
    # Compil Stratum
    cd $HOME/yiimp/stratum
    if [[ ("$BTC" == "y" || "$BTC" == "Y") ]]; then
    sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $HOME/yiimp/stratum/Makefile
    fi
    hide_output sudo make
    
    # Copy Files (Blocknotify,iniparser,Stratum)
    cd $HOME/yiimp
	if [[ ("$yiimpver" == "1" || "$yiimpver" == "" || "$yiimpver" == "4") ]];then 
		sudo sed -i 's/myadmin/'$admin_panel'/' $HOME/yiimp/web/yaamp/modules/site/SiteController.php
	else
		sudo sed -i 's/AdminRights/'$admin_panel'/' $HOME/yiimp/web/yaamp/modules/site/SiteController.php
	fi

	URLREPLACEWEBVAR=/var/web
	URLSHYIIMPDATA=/home/yiimp-data/yiimp/site/web
	URLSHCRYPTODATA=/home/crypto-data/yiimp/site/web

	cd $HOME/yiimp/web/

	find ./ -type f -exec sed -i 's@'${URLSHYIIMPDATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3
	find ./ -type f -exec sed -i 's@'${URLSHCRYPTODATA}'@'${URLREPLACEWEBVAR}'@g' {} \;
	sleep 3

	URLREPLACEWEBWAL=$HOME/wallets/
	URLSEARCHWEBWAL=/home/crypto-data/wallets/
	sleep 3
	find ./ -type f -exec sed -i 's@'${URLSEARCHWEBWAL}'@'${URLREPLACEWEBWAL}'@g' {} \;
	sleep 3
	
	cd $HOME/yiimp
	
    sudo cp -r $HOME/yiimp/web /var/
    sudo mkdir -p /var/stratum
    cd $HOME/yiimp/stratum
    sudo cp -a config.sample/. /var/stratum/config
    sudo cp -r stratum /var/stratum
    sudo cp -r run.sh /var/stratum
    cd $HOME/yiimp
    sudo cp -r $HOME/yiimp/bin/. /bin/
    sudo cp -r $HOME/yiimp/blocknotify/blocknotify /usr/bin/
    sudo cp -r $HOME/yiimp/blocknotify/blocknotify /var/stratum/
    sudo mkdir -p /etc/yiimp
    sudo mkdir -p /$HOME/backup/
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
    exec bash
    ' | sudo -E tee /var/stratum/config/run.sh >/dev/null 2>&1
    sudo chmod +x /var/stratum/config/run.sh

    echo -e "$GREEN Done...$COL_RESET"


    # Update Timezone
    echo
    echo
    echo -e "$CYAN => Update default timezone. $COL_RESET"
    echo
    
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
    echo
    echo -e "$GREEN Done...$COL_RESET"
    
    
    # Making Web Server Magic Happen
    #echo
    #echo -e "$CYAN Making Web Server Magic Happen! $COL_RESET"
    #echo
    
    # Adding user to group, creating dir structure, setting permissions
    #sudo mkdir -p /var/www/$server_name/html 
    
    
    # Creating webserver initial config file
    echo
    echo
    echo -e "$CYAN => Creating webserver initial config file $COL_RESET"
    echo
    
    # Adding user to group, creating dir structure, setting permissions
    sudo mkdir -p /var/www/$server_name/html

    if [[ ("$sub_domain" == "y" || "$sub_domain" == "Y") ]]; then
    echo 'include /etc/nginx/blockuseragents.rules;
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
        root "/var/www/'"${server_name}"'/html/web";
        index index.html index.htm index.php;
        charset utf-8;
    
        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }
    
        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }
    
        access_log /var/log/nginx/'"${server_name}"'.app-access.log;
        error_log /var/log/nginx/'"${server_name}"'.app-error.log;
    
        # allow larger file uploads and longer script runtimes
		client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 50k;
        large_client_header_buffers 2 50k;
        sendfile off;
    
        location ~ ^/index\.php$ {
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
		location ~ \.php$ {
        	return 404;
        }
		location ~ \.sh {
		return 404;
        }
		location ~ /\.ht {
		deny all;
        }
		location ~ /.well-known {
		allow all;
        }
		location /phpmyadmin {
  		root /usr/share/;
  		index index.php;
  		try_files $uri $uri/ =404;
  		location ~ ^/phpmyadmin/(doc|sql|setup)/ {
    		deny all;
  	  }
  		location ~ /phpmyadmin/(.+\.php)$ {
    		fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    		include fastcgi_params;
    		include snippets/fastcgi-php.conf;
  	    }
      }
    }
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

    sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
    sudo ln -s /var/web /var/www/$server_name/html
    hide_output sudo systemctl reload php7.3-fpm.service
    hide_output sudo systemctl restart nginx.service
    echo -e "$GREEN Done...$COL_RESET"
    	
    if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then

    
    # Install SSL (with SubDomain)
    echo
    echo -e "Install LetsEncrypt and setting SSL (with SubDomain)"
    echo
    
    apt_install letsencrypt
    sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name"
    sudo rm /etc/nginx/sites-available/$server_name.conf
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    # I am SSL Man!
	echo 'include /etc/nginx/blockuseragents.rules;
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
    	# enforce https
        return 301 https://$server_name$request_uri;
	}
	
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
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
        
        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }
    
        
            location ~ ^/index\.php$ {
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
		location ~ \.php$ {
        	return 404;
        }
		location ~ \.sh {
		return 404;
        }
        
            location ~ /\.ht {
                deny all;
            }
	    location /phpmyadmin {
  		root /usr/share/;
  		index index.php;
  		try_files $uri $uri/ =404;
  		location ~ ^/phpmyadmin/(doc|sql|setup)/ {
    		deny all;
  	}
  		location ~ /phpmyadmin/(.+\.php)$ {
    		fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    		include fastcgi_params;
    		include snippets/fastcgi-php.conf;
  	   }
     }
    }
        
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1
	fi
	
	hide_output sudo systemctl reload php7.3-fpm.service
	hide_output sudo systemctl restart nginx.service
	echo -e "$GREEN Done...$COL_RESET"
	
	
	else
	echo 'include /etc/nginx/blockuseragents.rules;
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"' www.'"${server_name}"';
        root "/var/www/'"${server_name}"'/html/web";
        index index.html index.htm index.php;
        charset utf-8;
    
        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }
    
        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }
    
        access_log /var/log/nginx/'"${server_name}"'.app-access.log;
        error_log /var/log/nginx/'"${server_name}"'.app-error.log;
    
        # allow larger file uploads and longer script runtimes
 	client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 50k;
        large_client_header_buffers 2 50k;
        sendfile off;
    
        location ~ ^/index\.php$ {
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
		location ~ \.php$ {
        	return 404;
        }
		location ~ \.sh {
		return 404;
        }
		location ~ /\.ht {
		deny all;
        }
		location ~ /.well-known {
		allow all;
        }
		location /phpmyadmin {
  		root /usr/share/;
  		index index.php;
  		try_files $uri $uri/ =404;
  		location ~ ^/phpmyadmin/(doc|sql|setup)/ {
    		deny all;
  	}
  		location ~ /phpmyadmin/(.+\.php)$ {
    		fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    		include fastcgi_params;
    		include snippets/fastcgi-php.conf;
  	    }
      }
    }
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

    sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
    sudo ln -s /var/web /var/www/$server_name/html
    hide_output sudo systemctl reload php7.3-fpm.service
    hide_output sudo systemctl restart nginx.service
    echo -e "$GREEN Done...$COL_RESET"
   
	
    if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then
    
    # Install SSL (without SubDomain)
    echo
    echo -e "Install LetsEncrypt and setting SSL (without SubDomain)"
    echo
    sleep 3
    
    apt_install letsencrypt
    sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name" -d www."$server_name"
    sudo rm /etc/nginx/sites-available/$server_name.conf
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    # I am SSL Man!
	echo 'include /etc/nginx/blockuseragents.rules;
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
    	# enforce https
        return 301 https://$server_name$request_uri;
	}
	
	server {
	if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
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
        
        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }
    
        
            location ~ ^/index\.php$ {
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
		location ~ \.php$ {
        	return 404;
        }
		location ~ \.sh {
		return 404;
        }
        
            location ~ /\.ht {
                deny all;
            }
	    location /phpmyadmin {
  		root /usr/share/;
  		index index.php;
  		try_files $uri $uri/ =404;
  		location ~ ^/phpmyadmin/(doc|sql|setup)/ {
    		deny all;
  	}
  		location ~ /phpmyadmin/(.+\.php)$ {
    		fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    		include fastcgi_params;
    		include snippets/fastcgi-php.conf;
  	    }
      }
    }
        
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

	echo -e "$GREEN Done...$COL_RESET"

    fi
    hide_output sudo systemctl reload php7.3-fpm.service
    hide_output sudo systemctl restart nginx.service
    fi
    
    
    # Config Database
    echo
    echo
    echo -e "$CYAN => Now for the database fun! $COL_RESET"
    echo
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
    
    echo '
    [clienthost1]
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
    password='"${rootpasswd}"'
    ' | sudo -E tee ~/.my.cnf >/dev/null 2>&1
      sudo chmod 0600 ~/.my.cnf


    # Create keys file
    echo '  
    <?php
    /* Sample config file to put in /etc/yiimp/keys.php */
    define('"'"'YIIMP_MYSQLDUMP_USER'"'"', '"'"'panel'"'"');
    define('"'"'YIIMP_MYSQLDUMP_PASS'"'"', '"'"''"${password}"''"'"');
    define('"'"'YIIMP_MYSQLDUMP_PATH'"'"', '"'"''"/var/yiimp/sauv"''"'"');
    
    /* Keys required to create/cancel orders and access your balances/deposit addresses */
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
	define('"'"'EXCH_CRYPTOPIA_SECRET'"'"', '"'"''"'"');
	define('"'"'EXCH_NOVA_SECRET'"'"','"'"''"'"');
    ' | sudo -E tee /etc/yiimp/keys.php >/dev/null 2>&1

 	echo -e "$GREEN Done...$COL_RESET"

 
    # Peforming the SQL import
    echo
    echo
    echo -e "$CYAN => Database 'yiimpfrontend' and users 'panel' and 'stratum' created with password $password and $password2, will be saved for you $COL_RESET"
    echo
    echo -e "Performing the SQL import"
    echo
    sleep 3
    
    cd ~
    cd yiimp/sql


    if [[ ("$yiimpver" == "1" || "$yiimpver" == "") ]];then
		# Kudaraidee Sql

		# Import sql dump
		sudo zcat 2021-06-21-yaamp.sql.gz | sudo mysql --defaults-group-suffix=host1

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
    elif [[ "$yiimpver" == "2" ]]; then
		# Tpruvot Sql

		# Import sql dump
		sudo zcat 2016-04-03-yaamp.sql.gz | sudo mysql --defaults-group-suffix=host1

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
	elif [[ "$yiimpver" == "3" ]]; then
		# Afiniel Tech Sql


		# Import sql dump
		sudo zcat 2016-04-03-yaamp.sql.gz | sudo mysql --defaults-group-suffix=host1

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
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2019-11-10-yiimp.sql.gz
		hide_output sudo mysql --defaults-group-suffix=host1 --force < 2020-06-03-blocks.sql
	elif [[ "$yiimpver" == "4" ]]; then
		# Afiniel

		# Import sql dump
		# sudo zcat 2021-06-21-yaamp.sql.gz | sudo mysql --defaults-group-suffix=host1
		sudo zcat 2021-06-21-yaamp.sql.gz | sudo mysql --defaults-group-suffix=host1
		
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
		# sudo mysql --defaults-group-suffix=host1 --force < 2020-11-10-yaamp.sql.gz
		# sudo mysql --defaults-group-suffix=host1 --force < 2021-06-21-yaamp.sql.gz
	fi

    echo -e "$GREEN Done...$COL_RESET"    
    
    # Generating a basic Yiimp serverconfig.php
    echo
    echo
    echo -e "$CYAN => Generating a basic Yiimp serverconfig.php $COL_RESET"
    echo
    sleep 3
    
    # Make config file
echo '
    <?php
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
	
	define('"'"'YAAMP_CONTACT_EMAIL'"'"', '"'"'vaudese@gmail.com'"'"');

	define('"'"'YIIMP_VIEW_24H'"'"', false);

	// Google Analytics = '"'"''"'"' == disabled
	define('"'"'YAAMP_GOOGLE_ANALYTICS'"'"', '"'"''"'"');

	// Others server Stratums of inn Worl enter name Country ex: Europe
	define('"'"'YAAMP_THIS_SERVER_STRATUM', 'europe'"'"');
	define('"'"'YAAMP_SERVERS_STRATUMS'"'"', array(
	'"'"'europe'"'"',
	'"'"'asia'"'"',
	));

	// use chat from CHATBRO.COM
	define('"'"'YAAMP_CHATBRO'"'"', true);
	define('"'"'YAAMP_CHATBRO_CONFIG_WEB'"'"', false);
	define('"'"'YAAMP_CHATBRO_ID'"'"', '"'"'18UYt'"'"');
	// YAAMP_CHATBRO_CONFIG_WEB is false you can put the name of indefinite chats eg = chat1, new = chat2, new = chat3...
	define('"'"'YAAMP_CHATBRO_CUSTOM_NAME'"'"', '"'"'090822'"'"');

	// Bottom links social
	define('"'"'YAAMP_LINK_DISCORD'"'"', '"'"'DD4rhgwySG'"'"');
	define('"'"'YAAMP_LINK_TWITTER'"'"', true);
	define('"'"'YAAMP_LINK_MAILCONTACT'"'"', YAAMP_CONTACT_EMAIL);

	# TELEGRAM CONFIG BOT AND URL
	define('"'"'YAAMP_LINK_TELEGRAM'"'"', '"'"'+DMgAs-7cwNEzYmFk'"'"');
	define('"'"'YAAMP_BOT_TOKEN_TELEGRAM'"'"', '"'"'5564362856:AAG05ljMt7-67F8u5Fmyg8QmOK0nJMcMQxM'"'"');
	define('"'"'YAAMP_CHAT_ID_TELEGRAM'"'"', '"'"'-661569030'"'"');

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
	));

    ' | sudo -E tee /var/web/serverconfig.php >/dev/null 2>&1


    echo -e "$GREEN Done...$COL_RESET"


    # Updating stratum config files with database connection info
    echo
    echo
    echo -e "$CYAN => Updating stratum config files with database connection info. $COL_RESET"
    echo
    sleep 3
 
    cd /var/stratum/config
    sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
    sudo sed -i 's/server = yaamp.com/server = '$server_name'/g' *.conf
    sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
    sudo sed -i 's/database = yaamp/database = yiimpfrontend/g' *.conf
    sudo sed -i 's/username = root/username = stratum/g' *.conf
    sudo sed -i 's/password = patofpaq/password = '$password2'/g' *.conf
    cd ~
    echo -e "$GREEN Done...$COL_RESET"


    # Final Directory permissions
    echo
    echo
    echo -e "$CYAN => Final Directory permissions $COL_RESET"
    echo
    sleep 3

    whoami=`whoami`
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

    #Add to contrab screen-scrypt
    (crontab -l 2>/dev/null; echo "@reboot sleep 20 && /etc/screen-scrypt.sh") | crontab -

    #fix error screen main
    sudo sed -i 's/service $webserver start/sudo service $webserver start/g' /var/web/yaamp/modules/thread/CronjobController.php
    sudo sed -i 's/service nginx stop/sudo service nginx stop/g' /var/web/yaamp/modules/thread/CronjobController.php

    #Misc
    sudo rm -rf $HOME/yiimp
    sudo rm -rf $HOME/yiimp_install_scrypt
    sudo rm -rf /var/log/nginx/*

    #Restart service
    sudo systemctl restart cron.service
    sudo systemctl restart mysql
    sudo systemctl status mysql | sed -n "1,3p"
    sudo systemctl restart nginx.service
    sudo systemctl status nginx | sed -n "1,3p"
    sudo systemctl restart php7.3-fpm.service
    sudo systemctl status php7.3-fpm | sed -n "1,3p"

    echo
    echo -e "$GREEN Done...$COL_RESET"
    sleep 3

	echo
	install_end_message
	echo
