#!/bin/bash
# PLEASE DO NOT SET ANY OF THE VARIABLES, THEY WILL BE POPULATED IN THE MENU
clear

# Formatting variables
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
LBLUE=$(tput setaf 6)
RED=$(tput setaf 1)
PURPLE=$(tput setaf 5)

# The system user rtorrent is going to run as
RTORRENT_USER=""

# The user that is going to log into rutorrent (htaccess)
WEB_USER=""

# Array with webusers including their hashed paswords
WEB_USER_ARRAY=()

# Temporary download folder for plugins
TEMP_PLUGIN_DIR="/tmp/rutorrentPlugins"

# Array of downloaded plugins
PLUGIN_ARRAY=()

#rTorrent users home dir.
HOMEDIR=""

# Function to check if running user is root
function CHECK_ROOT {
	if [ "$(id -u)" != "0" ]; then
		echo
		echo "This script must be run as root." 1>&2
		echo
		exit 1
	fi
}

# License
function LICENSE {
	clear
	echo "${BOLD}--------------------------------------------------------------------------------"
	echo " THE BEER-WARE LICENSE (Revision 42):"
	echo " <patrick@kerwood.dk> wrote this script. As long as you retain this notice you"
	echo " can do whatever you want with this stuff. If we meet some day, and you think"
	echo " this stuff is worth it, you can buy me a beer in return."
	echo
	echo " - ${LBLUE}Patrick Kerwood @ LinuxBloggen.dk${NORMAL}"
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
	read -p " Press any key to continue..." -n 1
	echo
}

# Function to set the system user, rtorrent is going to run as
function SET_RTORRENT_USER {
	con=0
	while [ $con -eq 0 ]; do
		echo -n "Please type a valid system user: "
		read RTORRENT_USER

		if [ -z $(cat /etc/passwd | grep "^$RTORRENT_USER:") ]; then
			echo
			echo "This user does not exist!"
		elif [ $(cat /etc/passwd | grep "^$RTORRENT_USER:" | cut -d: -f3) -lt 999 ]; then
			echo
			echo "That user's UID is too low!"
		elif [ $RTORRENT_USER == nobody ]; then
			echo
			echo "You cant use 'nobody' as user!"
		else
			HOMEDIR=$(cat /etc/passwd | grep "$RTORRENT_USER": | cut -d: -f6)
			con=1
		fi
	done
}

# Function to  create users for the webinterface
function SET_WEB_USER {
	apt-get update
	apt-get -y install apache2-utils curl
	while true; do
		echo -n "Please type the username for the webinterface, system user not required: "
		read WEB_USER
		USER=$(htpasswd -n $WEB_USER 2>/dev/null)
		if [ $? = 0 ]; then
			WEB_USER_ARRAY+=($USER)
			break
		else
			echo
			echo "${RED}Something went wrong!"
			echo "You have entered an unusable username and/or different passwords.${NORMAL}"
			echo
		fi
	done
}

# Function to list WebUI users in the menu
function LIST_WEB_USERS {
	for i in ${WEB_USER_ARRAY[@]}; do
		USER_CUT=$(echo $i | cut -d \: -f 1)
		echo -n " $USER_CUT"
	done
}

# Function to list plugins, downloaded, in the menu
function LIST_PLUGINS {
	if [ ${#PLUGIN_ARRAY[@]} -eq 0 ]; then
		echo "   No plugins downloaded!"
	else
		for i in "${PLUGIN_ARRAY[@]}"; do
			echo "   - $i"
		done
	fi
}

# Header for the menu
function HEADER {
	clear
	echo "${BOLD}--------------------------------------------------------------------------------"
	echo "                       Rtorrent + Rutorrent Auto Install"
	echo "                       ${LBLUE}Patrick Kerwood @ LinuxBloggen.dk${NORMAL}"
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
}

# Function for the Plugins download part.
function DOWNLOAD_PLUGIN {
	if [ ! -d $TEMP_PLUGIN_DIR ]; then
		mkdir $TEMP_PLUGIN_DIR
	fi
	name="Logoff Plugin v1.3"
	url="http://rutorrent-logoff.googlecode.com/files/logoff-1.3.tar.gz"
	file="logoff-1.3.tar.gz"
	desc="This plugin allows you to switch users or logoff on systems which use authentication.\nhttp://code.google.com/p/rutorrent-logoff/"
	unpack="tar -zxf $file -C $TEMP_PLUGIN_DIR"
	curl -L "$url" -o $file
	$unpack
	rm "$file"
				
	name="Plugins v3.6"
	url="http://dl.bintray.com/novik65/generic/plugins-3.6.tar.gz"
	file="plugins-3.6.tar.gz"
	desc="This installs about 40+ plugins except plugins number 29 to 33 (NFO, Chat, Logoff, Pause and Instant Search).\nMore info at https://github.com/Novik/ruTorrent/wiki/Plugins \nAll dependencies will be installed. \n${RED}REMEBER TO REMOVE HTTPRPC AND RPC PLUGINS FOR LOGIN TO WORK AT FIRST RUN!${NORMAL}"
	unpack="tar -zxf $file -C /tmp/"
	echo
	curl -L "$url" -o $file
	$unpack
	if [ $? -eq "0" ]; then
		rm "$file"
		echo
		PLUGIN_ARRAY+=("${name}")
		error="${GREEN}${BOLD}$name${NORMAL}${GREEN} downloaded, unpacked and moved to temporary plugins folder${NORMAL}"
		mv /tmp/plugins/* $TEMP_PLUGIN_DIR
		rm -R $TEMP_PLUGIN_DIR/rpc $TEMP_PLUGIN_DIR/httprpc
		INSTALL_FFMPEG
		apt-get -y install php5-geoip curl libzen0 libmediainfo0 mediainfo unrar-free
		return 0
	else
		echo
		error="${RED}Something went wrong.. Error!${NORMAL}"
		return 1
	fi
	echo
}

# Function for installing dependencies
function APT_DEPENDENCIES {
	apt-get purge apache2 apache2.2-bin apache2-common
	apt-get remove apache2
	apt-get autoremove
	apt-get -y install software-properties-common
	add-apt-repository 'deb http://packages.dotdeb.org jessie all'
	wget https://www.dotdeb.org/dotdeb.gpg
	apt-key add dotdeb.gpg
	apt-get update
	apt-get -y install openssl git build-essential libsigc++-2.0-dev \
	libcurl4-openssl-dev automake libtool libcppunit-dev libncurses5-dev \
	php5 php5-curl php5-cli tmux unzip libssl-dev curl unzip nginx php5-fpm
}

# Function for setting up xmlrpc, libtorrent and rtorrent
function INSTALL_RTORRENT {
	# Use the temp folder for compiling
	cd /tmp

	# Download and install xmlrpc-c super-stable
	curl -L http://sourceforge.net/projects/xmlrpc-c/files/latest/download -o xmlrpc-c-latest.tgz
	tar zxf xmlrpc-c-latest.tgz
	mv xmlrpc-c-1.* xmlrpc
	cd xmlrpc
	./configure
	make
	make install

	cd ..
	rm -r xmlrpc*

	mkdir rtorrent
	cd rtorrent

	# Download and install libtorrent
	curl -L https://github.com/rakshasa/libtorrent/archive/0.13.4.tar.gz -o libtorrent-0.13.4.tar.gz
	tar -zxf libtorrent-0.13.4.tar.gz
	cd libtorrent-0.13.4
	./autogen.sh
	./configure
	make
	make install

	cd ..

	# Download and install rtorrent
	curl -L https://github.com/rakshasa/rtorrent/archive/0.9.4.tar.gz -o rtorrent-0.9.4.tar.gz
	tar -zxf rtorrent-0.9.4.tar.gz
	cd rtorrent-0.9.4
	./autogen.sh
	./configure --with-xmlrpc-c
	make
	make install

	cd ../..
	rm -r rtorrent

	ldconfig

	# Creating session directory
	if [ ! -d "$HOMEDIR"/.rtorrent-session ]; then
		mkdir "$HOMEDIR"/.rtorrent-session
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/.rtorrent-session
	else
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/.rtorrent-session
	fi

	# Creating downloads folder
	if [ ! -d "$HOMEDIR"/downloads ]; then
		mkdir "$HOMEDIR"/downloads
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/downloads
	else
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/downloads
	fi
	# Creating watch folder
	if [ ! -d "$HOMEDIR"/watch ]; then
		mkdir "$HOMEDIR"/watch
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/watch
	else
		chown "$RTORRENT_USER"."$RTORRENT_USER" "$HOMEDIR"/watch
	fi

	# Downloading rtorrent.rc file.
	wget -O $HOMEDIR/.rtorrent.rc https://gitlab.open-scene.net/upload-bots/upload-bot-installer/raw/master/rtorrent.rc
	chown "$RTORRENT_USER"."$RTORRENT_USER" $HOMEDIR/.rtorrent.rc
	sed -i "s@HOMEDIRHERE@$HOMEDIR@g" $HOMEDIR/.rtorrent.rc
}

# Function for installing rutorrent and plugins
function INSTALL_RUTORRENT {
	# Installing rutorrent.
	curl -L http://dl.bintray.com/novik65/generic/rutorrent-3.6.tar.gz -o rutorrent-3.6.tar.gz
	tar -zxf rutorrent-3.6.tar.gz

	if [ -d /var/www/rutorrent ]; then
		rm -r /var/www/rutorrent
	fi

	sed -i "s@\"curl\"\t=> '',@\"curl\"\t=> '\/usr\/bin\/curl',@g" ./rutorrent/conf/config.php

	mv -f rutorrent /var/www/
	rm rutorrent-3.6.tar.gz

	if [ -d "$TEMP_PLUGIN_DIR" ]; then
		mv -fv "$TEMP_PLUGIN_DIR"/* /var/www/rutorrent/plugins
	fi

	# Changing permissions for rutorrent and plugins.
	chown -R www-data.www-data /var/www/rutorrent
	chmod -R 775 /var/www/rutorrent
}

# Function for configuring nginx
function CONFIGURE_NGINX {
	# Install the required packages
	apt-get install -y nginx php5-fpm php5-cli

	# Stop nginx service and unlink/delete default config file
	service nginx stop >> /dev/null
	unlink /etc/nginx/sites-enabled/default

	# Create standard www folder and copy default index.html
	if [ ! -d /var/www ]; then mkdir -p /var/www; fi
	cp /usr/share/nginx/html/index.html /var/www/

	# Check and create new virtual host for rutorrent
	mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.original
	rm -f /etc/nginx/sites-enabled/default
	rm -f /etc/nginx/sites-available/rutorrent.conf

	if [ ! -f /etc/nginx/sites-available/rutorrent.conf ]; then
		cat >/etc/nginx/sites-available/rutorrent.conf <<- EOF
		server {
			root /var/www;
			index index.php index.html index.htm;

			location /rutorrent {
				access_log /var/log/nginx/rutorrent.access.log;
				error_log /var/log/nginx/rutorrent.error.log;
				auth_basic "Restricted";
				auth_basic_user_file /var/www/.htpasswd;
				location ~ .php$ {
					fastcgi_split_path_info ^(.+\.php)(.*)$;
					fastcgi_pass    backendrutorrent;
					fastcgi_index   index.php;
					fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
					include fastcgi_params;
					fastcgi_intercept_errors        on;
					fastcgi_ignore_client_abort     off;
					fastcgi_connect_timeout         60;
					fastcgi_send_timeout            180;
					fastcgi_read_timeout            180;
					fastcgi_buffer_size             128k;
					fastcgi_buffers                 4       256k;
					fastcgi_busy_buffers_size       256k;
					fastcgi_temp_file_write_size    256k;
				}
			}

			location /RPC2 {
				access_log /var/log/nginx/rutorrent.rpc2.access.log;
				error_log /var/log/nginx/rutorrent.rpc2.error.log;
				include /etc/nginx/scgi_params;
				scgi_pass backendrtorrent;
			}
		}
		EOF

		mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
		cat >/etc/nginx/nginx.conf <<- 'EOF'
		user www-data;
		worker_processes 4;
		pid /var/run/nginx.pid;

		events {
			worker_connections 1024;
		}

		http {
			log_format main '$remote_addr - $remote_user [$time_local] "$request" '
				'$status $body_bytes_sent "$http_referer" '
				'"$http_user_agent" "$http_x_forwarded_for"';

			include /etc/nginx/mime.types;
			default_type application/octet-stream;

			access_log /var/log/nginx-access.log main;
			error_log /var/log/nginx-error.log warn;

			client_max_body_size 100M;
			sendfile on;
			#tcp_nopush on;
			keepalive_timeout 65;
			#gzip on;

			upstream backendrtorrent {
				server 127.0.0.1:5000;
			}
			upstream backendrutorrent {
				server unix:/var/run/php-fpm-rutorrent.sock;
			}

			# Load virtual host conf files
			include /etc/nginx/sites-enabled/*;
		}
		EOF

		if [[ ! -d /etc/php5/fpm/pool.d ]]; then
			mkdir -vp /etc/php5/fpm/pool.d
		fi

		if [[ ! -f /etc/php5/fpm/pool.d/rutorrent.conf ]]; then
			cat >/etc/php5/fpm/pool.d/rutorrent.conf <<- 'EOF'
			[rutorrent]
			user = www-data
			group = www-data
			listen = /var/run/php-fpm-rutorrent.sock
			listen.owner = www-data
			listen.group = www-data
			listen.mode = 0660
			pm = static
			pm.max_children = 2
			pm.start_servers = 2
			pm.min_spare_servers = 1
			pm.max_spare_servers = 3
			chdir = /
			EOF
		fi

		# Modify php.ini for larger file uploads (torrents)
		sed -i -e '/upload_max_filesize =/ s/= .*/= 10M/' /etc/php5/fpm/php.ini
		sed -i -e '/post_max_size =/ s/= .*/= 125M/' /etc/php5/fpm/php.ini
		sed -i -e '/memory_limit =/ s/= .*/= 256M/' /etc/php5/fpm/php.ini # Possibly change this higher/lower.
		sed -i -e 's/;date.timezone.*/date.timezone = UTC/' /etc/php5/fpm/php.ini
		sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini

		# Add right user for php5-fpm
		sed -i "s/user = www-data/user = www-data/" /etc/php5/fpm/pool.d/www.conf
		sed -i "s/group = www-data/group = www-data/" /etc/php5/fpm/pool.d/www.conf
		sed -i "s/;listen\.owner.*/listen.owner = www-data/" /etc/php5/fpm/pool.d/www.conf
		sed -i "s/;listen\.group.*/listen.group = www-data/" /etc/php5/fpm/pool.d/www.conf
		sed -i "s/;listen\.mode.*/listen.mode = 0660/" /etc/php5/fpm/pool.d/www.conf # This passage in not required normally

		# Enable the nginx config file for rutorrent
		ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled

		# Enable the nginx config file for rutorrent
		ln -s /etc/nginx/sites-available/rutorrent.conf /etc/nginx/sites-enabled
	fi

	# Restart nginx and php5-fpm
	service nginx start >> /dev/null
	service php5-fpm restart >> /dev/null

	# Creating .htaccess file
	printf "%s\n" "${WEB_USER_ARRAY[@]}" > /var/www/.htpasswd
}

function INSTALL_FFMPEG {
	printf "\n# ffpmeg mirror\ndeb http://www.deb-multimedia.org jessie main non-free\n" >> /etc/apt/sources.list
	apt-get update
	apt-get -y --force-yes install deb-multimedia-keyring
	apt-get update
	apt-get -y install ffmpeg
}

# Function for showing the end result when install is complete
function INSTALL_COMPLETE {
	rm -rf $TEMP_PLUGIN_DIR

	HEADER

	echo "${GREEN}Installation is complete.${NORMAL}"
	echo
	echo "${PURPLE}Your downloads folder is in ${LBLUE}$HOMEDIR/downloads${NORMAL}"
	echo "${PURPLE}Sessions data is ${LBLUE}$HOMEDIR/.rtorrent-session${NORMAL}"
	echo "${PURPLE}rtorrent's configuration file is ${LBLUE}$HOMEDIR/.rtorrent.rc${NORMAL}"
	echo
	echo "${PURPLE}If you want to change settings for rtorrent, such as download folder, etc.,"
	echo "you need to edit the '.rtorrent.rc' file. E.g. 'nano $HOMEDIR/.rtorrent.rc'${NORMAL}"
	echo
	echo "Rtorrent can be started without rebooting with 'sudo systemctl start rtorrent.service'."

	# The IPv6 local address, is not very used for now, anyway if needed, just change 'inet' to 'inet6'
	lcl=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -v "127." | head -n 1)
	ext=$(curl -s http://icanhazip.com)

	if [[ ! -z "$lcl" ]] && [[ ! -z "$ext" ]]; then
		echo "${LBLUE}LOCAL IP:${NORMAL} http://$lcl/rutorrent"
		echo "${LBLUE}EXTERNAL IP:${NORMAL} http://$ext/rutorrent"
		echo
		echo "Visit rutorrent through the above address."
		echo 
	else
		if [[ -z "$lcl" ]]; then
			echo "Can't detect the local IP address"
			echo "Try visit rutorrent at http://127.0.0.1/rutorrent"
			echo 
		elif [[ -z "$ext" ]]; then
			echo "${LBLUE}LOCAL:${NORMAL} http://$lcl/rutorrent"
			echo "Visit rutorrent through your local network"
		else
			echo "Can't detect the IP address"
			echo "Try visit rutorrent at http://127.0.0.1/rutorrent"
			echo 
		fi
	fi
}

function INSTALL_SYSTEMD_SERVICE {
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
	[Unit]
	Description=rtorrent (in tmux)

	[Service]
	Type=oneshot
	RemainAfterExit=yes
	User=$RTORRENT_USER
	ExecStart=/usr/bin/tmux -2 new-session -d -s rtorrent rtorrent
	ExecStop=/usr/bin/tmux kill-session -t rtorrent

	[Install]
	WantedBy=default.target
	EOF

	systemctl enable rtorrent.service
}

function START_RTORRENT {
	systemctl start rtorrent.service	
}

CHECK_ROOT
LICENSE
rm -rf $TEMP_PLUGIN_DIR
HEADER
SET_RTORRENT_USER
SET_WEB_USER

# NOTICE: Change lib, rtorrent, rutorrent versions on upgrades.
while true; do
	HEADER
	echo " ${BOLD}rTorrent version:${NORMAL} ${RED}0.9.4${NORMAL}"
	echo " ${BOLD}libTorrent version:${NORMAL} ${RED}0.13.4${NORMAL}"
	echo " ${BOLD}ruTorrent version:${NORMAL} ${RED}3.6${NORMAL}"
	echo
	echo " ${BOLD}rTorrent user:${NORMAL}${GREEN} $RTORRENT_USER${NORMAL}"
	echo
	echo -n " ${BOLD}ruTorrent user(s):${NORMAL}${GREEN}"
	LIST_WEB_USERS
	echo
	echo
	echo " ${NORMAL}${BOLD}ruTorrent plugins:${NORMAL}${GREEN}"
	LIST_PLUGINS
	echo
	echo " ${NORMAL}[1] - Change rTorrent user"
	echo " [2] - Add another ruTorrent user"
	echo
	echo " [0] - Start installation"
	echo " [q] - Quit"
	echo
	echo -n "${GREEN}>>${NORMAL} "
	read case

	case "$case" in
		1)
			SET_RTORRENT_USER
			;;
		2)
			SET_WEB_USER
			;;
		0)
			DOWNLOAD_PLUGIN
			APT_DEPENDENCIES
			INSTALL_RTORRENT
			INSTALL_RUTORRENT
			CONFIGURE_NGINX
			INSTALL_SYSTEMD_SERVICE
			START_RTORRENT
			INSTALL_COMPLETE
			break
			;;
		q)
			break
			;;
	esac
done
