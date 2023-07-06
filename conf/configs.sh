#!/bin/bash
#####################################################
# Modified by Vaudois for crypto use...
#####################################################

function confnginxsslsub
{
# Install SSL (with SubDomain)
echo '#####################################################
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
	server_name '"$1"' '"$2"'.'"$1"';

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
	server_name '"$1"' '"$2"'.'"$1"';
	root /var/www/'"$1"'/html/web;
	index index.php;
	access_log /var/log/yiimp/'"$1"'.app-access.log;
	error_log  /var/log/yiimp/'"$1"'.app-error.log;

	# allow larger file uploads and longer script runtimes
	client_body_buffer_size  50k;
	client_header_buffer_size 50k;
	client_max_body_size 50k;
	large_client_header_buffers 2 50k;
	sendfile off;

	# strengthen ssl security
	ssl_certificate /etc/letsencrypt/live/'"$1"'/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/'"$1"'/privkey.pem;
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
		fastcgi_pass unix:/var/run/php/php'"$3"'-fpm.sock;
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
			fastcgi_pass unix:/run/php/php'"$3"'-fpm.sock;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			include fastcgi_params;
			include snippets/fastcgi-php.conf;
		}
	}
	# additional config
	include /etc/yiimp/nginxCustom.conf;
}' | sudo -E tee /etc/nginx/sites-available/$1.conf >/dev/null 2>&1
}

function confnginxsslnotsub
{
# Install SSL (without SubDomain)
echo '#####################################################
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
	server_name '"$1"';
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
	server_name '"$1"' www.'"$1"';

	root /var/www/'"$1"'/html/web;
	index index.php;

	access_log /var/log/yiimp/'"$1"'.app-access.log;
	error_log  /var/log/yiimp/'"$1"'.app-error.log;

	# allow larger file uploads and longer script runtimes
	client_body_buffer_size  50k;
	client_header_buffer_size 50k;
	client_max_body_size 50k;
	large_client_header_buffers 2 50k;
	sendfile off;
	
	# strengthen ssl security
	ssl_certificate /etc/letsencrypt/live/'"$1"'/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/'"$1"'/privkey.pem;
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
		fastcgi_pass unix:/var/run/php/php'"$2"'-fpm.sock;
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
			fastcgi_pass unix:/run/php/php'"$2"'-fpm.sock;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			include fastcgi_params;
			include snippets/fastcgi-php.conf;
		}
	}
	# additional config
	include /etc/yiimp/nginxCustom.conf;
}' | sudo -E tee /etc/nginx/sites-available/$1.conf >/dev/null 2>&1
}

function confnginxnotsslsub
{
# Install without SSL (with SubDomain)
echo '#####################################################
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
	server_name '"$1"' '"$2"'.'"$1"';
	root "/var/www/'"$1"'/html/web";
	index index.php;
	#charset utf-8;

	location /
	{
		try_files $uri $uri/ /index.php?$args;
	}
	location @rewrite
	{
		rewrite ^/(.*)$ /index.php?r=$1;
	}

	access_log /var/log/yiimp/'"$1"'.app-access.log;
	error_log /var/log/yiimp/'"$1"'.app-error.log;

	# allow larger file uploads and longer script runtimes
	client_body_buffer_size  50k;
	client_header_buffer_size 50k;
	client_max_body_size 50k;
	large_client_header_buffers 2 50k;
	sendfile off;

	location ~ ^/index\.php$
	{
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/var/run/php/php'"$3"'-fpm.sock;
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
			fastcgi_pass unix:/run/php/php'"$3"'-fpm.sock;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			include fastcgi_params;
			include snippets/fastcgi-php.conf;
		}
	}
	# additional config
	include /etc/yiimp/nginxCustom.conf;
}' | sudo -E tee /etc/nginx/sites-available/$1.conf >/dev/null 2>&1
}

function confnginxnotssl
{
# Install without SSL
echo '#####################################################
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
	server_name '"$1"' www.'"$1"';
	root "/var/www/'"$1"'/html/web";
	index index.html index.htm index.php;
	#charset utf-8;
	location /
	{
		try_files $uri $uri/ /index.php?$args;
	}
	location @rewrite
	{
		rewrite ^/(.*)$ /index.php?r=$1;
	}

	access_log /var/log/yiimp/'"$1"'.app-access.log;
	error_log /var/log/yiimp/'"$1"'.app-error.log;

	# allow larger file uploads and longer script runtimes
	client_body_buffer_size  50k;
	client_header_buffer_size 50k;
	client_max_body_size 50k;
	large_client_header_buffers 2 50k;
	sendfile off;
	location ~ ^/index\.php$
	{
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/var/run/php/php'"$2"'-fpm.sock;
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
		fastcgi_pass unix:/run/php/php'"$2"'-fpm.sock;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		include fastcgi_params;
		include snippets/fastcgi-php.conf;
		}
	}
	# additional config
	include /etc/yiimp/nginxCustom.conf;
}' | sudo -E tee /etc/nginx/sites-available/$1.conf >/dev/null 2>&1
}

function nginxcustomconf
{
# Custom config for nginx
echo '#####################################################
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
#location ~* \.(?:css(\.map)?|js(\.map)?|jpe?g|png|gif|ico|cur|heic|webp|tiff?|mp3|m4a|aac|ogg|midi?|wav|mp4|mov|webm|mpe?g|avi|ogv|flv|wmv)$ {
#	expires 7d;
#	access_log off;
#}

# svg, fonts
location ~* \.(?:svgz?|ttf|ttc|otf|eot|woff2?)$ {
	add_header Access-Control-Allow-Origin "*";
	expires 7d;
	access_log off;
}

location ^~ /list-algos/ {
	deny all;
	access_log off;
	return 301 https://'"$1"';
}

# gzip
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
' | sudo -E tee /etc/yiimp/nginxCustom.conf >/dev/null 2>&1
}

function getserverconfig
{
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
define('"'"'YAAMP_DBPASSWORD'"'"', '"'"''"$1"''"'"');
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
define('"'"'YIIMP_VOTE'"'"', true);
define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false);
define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'USD'"'"'); // USD is main
define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);
define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');
define('"'"'YAAMP_SITE_URL'"'"', '"'"''"$2"''"'"');
define('"'"'YAAMP_STRATUM_URL'"'"', YAAMP_SITE_URL); // change if your stratum server is on a different host
define('"'"'YAAMP_SITE_NAME'"'"', '"'"'MyYiimpPool'"'"');
define('"'"'YAAMP_ADMIN_EMAIL'"'"', '"'"''"$3"''"'"');
define('"'"'YAAMP_ADMIN_IP'"'"', '"'"''"$4"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
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
);' | sudo -E tee /var/web/serverconfig.php >/dev/null 2>&1

}

function getconfkeys
{
echo '<?php
/* Sample config file to put in /etc/yiimp/keys.php */
define('"'"'YIIMP_MYSQLDUMP_USER'"'"', '"'"''"$1"''"'"');
define('"'"'YIIMP_MYSQLDUMP_PASS'"'"', '"'"''"$2"''"'"');

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
}

function addmoreserverconfigvaudois
{
echo -e '\n\n// #### More configs from Others Yiimp From Vaudois Github ####
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
));' | sudo tee -a /var/web/serverconfig.php >/dev/null 2>&1
}

function addmoreserverconfig5
{
	echo -e "\n\n// #### More configs from Others Yiimp (BETA) ####" | sudo tee -a /var/web/serverconfig.php >/dev/null 2>&1	
	echo -e "define('YAAMP_ADIM_LTE', true);\ndefine('LTE_LAYAUT', 'lte');\ndefine('LTE_DEFAULT_CARD', '');\ndefine('YAAMP_ANTI_ADBLOCK', false);\ndefine('LTE_SHOW_MESSAGES_DROPDOWN_MENU', true);\ndefine('LTE_SHOW_NOTIFICATIONS_MENU', true);\ndefine('YAAMP_NEW_COINS', 20*86400);\ndefine('YAAMP_HOT_ALGO', 15);" | sudo tee -a /var/web/serverconfig.php >/dev/null 2>&1
	echo -e "define('YAAMP_URGEN_NOTE',\n	array(\n		array(\n			'HOME',\n			'#33FF4C',\n			null,\n			'This urgent note is configured in: var/web/serverconfig.php'\n		),\n	)\n);" | sudo tee -a /var/web/serverconfig.php >/dev/null 2>&1
}

function updatemotdrebootrequired
{
echo 'clear
run-parts /etc/update-motd.d/ | sudo tee /etc/motd' | sudo -E tee /usr/bin/motd >/dev/null 2>&1
sudo chmod 755 /usr/bin/motd

echo '#!/bin/sh -e
#
# helper for update-motd

if [ -f /var/run/reboot-required ]; then
	cat /var/run/reboot-required
fi' | sudo -E tee /usr/lib/update-notifier/update-motd-reboot-required >/dev/null 2>&1
sudo chmod 755 /usr/lib/update-notifier/update-motd-reboot-required
}

function updatemotdupdatesavailable
{
echo '#!/bin/sh -e
#
# helper for update-motd

# poor mans force
if [ "$1" = "--force" ]; then
	NEED_UPDATE_CHECK=yes
else
	NEED_UPDATE_CHECK=no
fi

# check time when we did the last update check
stamp="/var/lib/update-notifier/updates-available"

# get list dir
StateDir="/var/lib/apt/"
ListDir="lists/"
eval "$(apt-config shell StateDir Dir::State)"
eval "$(apt-config shell ListDir Dir::State::Lists)"

# get dpkg status file
DpkgStatus="/var/lib/dpkg/status"
eval "$(apt-config shell DpkgStatus Dir::State::status)"

# get sources.list file
EtcDir="etc/apt/"
SourceList="sources.list"
eval "$(apt-config shell EtcDir Dir::Etc)"
eval "$(apt-config shell SourceList Dir::Etc::sourcelist)"

# let the actual update be asynchronous to avoid stalling apt-get
cleanup() { rm -f "$tmpfile"; }

# check if we have a list file or sources.list that needs checking
if [ -e "$stamp" ]; then
	if [ "$(find "/$StateDir/$ListDir" "/$EtcDir/$SourceList" "/$DpkgStatus" -type f -newer "$stamp" -print -quit)" ]; then
		NEED_UPDATE_CHECK=yes
	fi
else
	if [ "$(find "/$StateDir/$ListDir" "/$EtcDir/$SourceList" -type f -print -quit)" ]; then
		NEED_UPDATE_CHECK=yes
	fi
fi

tmpfile=""
trap cleanup EXIT
tmpfile=$(mktemp -p $(dirname "$stamp"))

# output something for update-motd
if [ "$NEED_UPDATE_CHECK" = "yes" ]; then
	{

		echo ""
		/usr/lib/update-notifier/apt-check --human-readable
		echo ""
	} > "$tmpfile"
	mv "$tmpfile" "$stamp"
fi' | sudo -E tee /usr/lib/update-notifier/update-motd-updates-available >/dev/null 2>&1
sudo chmod 755 /usr/lib/update-notifier/update-motd-updates-available
}

function updatemotdhweeol
{
echo '#!/bin/sh -e
#
# helper for update-motd

# poor mans force
if [ "$1" = "--force" ]; then
	NEED_EOL_CHECK=yes
else
	NEED_EOL_CHECK=no
fi

# check time when we did the last update check
stamp="/var/lib/update-notifier/hwe-eol"

# get list dir
StateDir="/var/lib/apt/"
ListDir="lists/"
eval "$(apt-config shell StateDir Dir::State)"
eval "$(apt-config shell ListDir Dir::State::Lists)"

# get dpkg status file
DpkgStatus="/var/lib/dpkg/status"
eval "$(apt-config shell DpkgStatus Dir::State::status)"

# get sources.list file
EtcDir="etc/apt/"
SourceList="sources.list"
eval "$(apt-config shell EtcDir Dir::Etc)"
eval "$(apt-config shell SourceList Dir::Etc::sourcelist)"

# let the actual update be asynchronous to avoid stalling apt-get
cleanup() { rm -f "$tmpfile"; }

# check if we have a list file or sources.list that needs checking
if [ -e "$stamp" ]; then
	if [ "$(find "/$StateDir/$ListDir" "/$EtcDir/$SourceList" "/$DpkgStatus" -type f -newer "$stamp" -print -quit)" ]; then
		NEED_EOL_CHECK=yes
	fi
else
	if [ "$(find "/$StateDir/$ListDir" "/$EtcDir/$SourceList" -type f -print -quit)" ]; then
		NEED_EOL_CHECK=yes
	fi
fi

tmpfile=""
trap cleanup EXIT
tmpfile=$(mktemp -p $(dirname "$stamp"))

# output something for update-motd
if [ "$NEED_EOL_CHECK" = "yes" ]; then
	{
		# the script may exit with status 10 when a HWE update is needed
		/usr/bin/hwe-support-status || true
	} > "$tmpfile"
	mv "$tmpfile" "$stamp"
fi

# output what we have (either cached or newly generated)
cat "$stamp"' | sudo -E tee /usr/lib/update-notifier/update-motd-hwe-eol >/dev/null 2>&1
sudo chmod 755 /usr/lib/update-notifier/update-motd-hwe-eol
}

function updatemotdfsckatreboot
{
echo '#!/bin/sh
# Authors:
#   Mads Chr. Olesen <mads@mchro.dk>
#   Kees Cook <kees@ubuntu.com>
set -e

# poor mans force
if [ "$1" = "--force" ]; then
	NEEDS_FSCK_CHECK=yes
fi

# check time when we did the last check
stamp="/var/lib/update-notifier/fsck-at-reboot"
if [ -e "$stamp" ]; then
	stampt=$(stat -c %Y $stamp)
else
	stampt=0
fi

# check time when we last booted
last_boot=$(date -d "now - $(awk '"'{print "'$1'"}'"' /proc/uptime) seconds" +%s)

now=$(date +%s)
if [ $(($stampt + 3600)) -lt $now ] || [ $stampt -gt $now ] \
   || [ $stampt -lt $last_boot ]
then
	#echo $stampt $now need update 
	NEEDS_FSCK_CHECK=yes
fi

# output something for update-motd
if [ -n "$NEEDS_FSCK_CHECK" ]; then
  {
	check_occur_any=

	ext_partitions=$(mount | awk '"'"'$5'" ~ /^ext(2|3|4)$/ { print "'$1'" }'"')
	for part in $ext_partitions; do
		dumpe2fs_out=$(dumpe2fs -h $part 2>/dev/null)
		mount_count=$(echo "$dumpe2fs_out" | grep "^Mount count:"|cut -d'"':'"' -f 2-)
		if [ -z "$mount_count" ]; then mount_count=0; fi
		max_mount_count=$(echo "$dumpe2fs_out" | grep "^Maximum mount count:"|cut -d'"':'"' -f 2-)
		if [ -z "$max_mount_count" ]; then max_mount_count=0; fi
		check_interval=$(echo "$dumpe2fs_out" | grep "^Check interval:" | cut -d'"':'"' -f 2- | cut -d'"'('"' -f 1)
		if [ -z "$check_interval" ]; then check_interval=0; fi
		next_check_date=$(echo "$dumpe2fs_out" | grep "^Next check after:" | cut -d'"':'"' -f 2-)
		if [ -z "$next_check_interval" ]; then next_check_interval=0; fi
		next_check_tstamp=$(date -d "$next_check_date" +%s)

		check_occur=
		# Check based on mount counts?
		if [ "$max_mount_count" -gt 0 -a \
			 "$mount_count" -ge "$max_mount_count" ]; then
			check_occur=yes
		fi
		# Check based on time passed?
		if [ "$check_interval" -gt 0 -a \
			 "$next_check_tstamp" -lt "$now" ]; then
			check_occur=yes
		fi
		if [ -n "$check_occur" ]; then
			check_occur_any=yes
			mountpoint=$(mount | grep "^$part" | cut -d '"' '"' -f 3)
			pass=$(grep -v '"'^#'"' /etc/fstab | tr -s '"' '"' '"'\t'"' | cut -s -f 2,6 | grep -w "$mountpoint" | cut -f 2)
			if [ "$pass" = "0" ]; then
				echo "*** $part should be checked for errors ***"
			else
				echo "*** $part will be checked for errors at next reboot ***"
			fi
		fi
	done
	if [ -n "$check_occur_any" ]; then
		echo ""
	fi
  } > $stamp
fi

# output what we have (either cached or newly generated)
cat $stamp' | sudo -E tee /usr/lib/update-notifier/update-motd-fsck-at-reboot >/dev/null 2>&1
sudo chmod 755 /usr/lib/update-notifier/update-motd-fsck-at-reboot
}
