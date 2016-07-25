#!/bin/bash

if [ ! -f /etc/flizbox.v7 ]
then
    if [ -d /root/flizbox ]
    then
        echo "You seem to have already installed an earlier version if flizbox on your system..."
        echo "Please reinstall your server if you wish to install flizbox v7. If you are trying"
        echo "to run the configuration script on flizbox v6 then you will need to run that"
        echo "version of flizbox to enter the config!"
        exit 0
    fi
else
    bash /root/scripts/flizbox-conf.sh
    exit 0
fi
exitHelp() {
    cat << EOF

    bash $0 [options]

Options:

-u user
    The username and site username. REQUIRED

-p
    The password for the user and site password. (will be the same otherwise use the interactive version) REQUIRED

-w
--webmin
    Install Webmin.

-d
--deluge
    Install Deluge

-z
--znc
    Install ZNC

-h
--help
    Show this help text

EOF
    exit 1
}

distro=$(lsb_release -a | grep Description | awk '{ printf $2" "$3" "$4 }')
os_version=$(lsb_release -a | grep Release | awk '{ printf $2 }')
arch=$(uname -m)
kscheck=$(hostname | cut -d. -f2)
wget http://coding.open-scene.net/ip.php -O ip -q
IP=$(cat ip)
rm ip
adlport=$(perl -e 'print int(rand(65000-64990))+64990')

clear
echo
echo `tput bold``tput sgr 0 1`"flizbox v7"`tput sgr0`" http://sourceforge.net/projects/flizbox/"
echo
echo "This script will install new versions of rtorrent, rutorrent, plugins, autodl,"
echo "lighttpd, web download folder, HTTPS and FTP. Optional: Deluge, ZNC, Webmin."
echo
echo "Once you have installed the seedbox, you can run this script again at a later"
echo "time and you will be given configuration options (password changes etc.)"
echo
echo "Press control-z if you don't want to install a seedbox anymore..!"
echo

until [[ $var9 == yes ]]; do
case $os_version in
        "10.04" | "11.04")
        ubuntu=yes
        deb8=no
        ub1011=yes
        deb6=no
        deb7=no
        var9=yes
        ub1011x=yes
        ;;
        "11.10")
        ubuntu=yes
        deb8=no
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=yes
        ;;
        "12.04")
        ubuntu=yes
        deb8=no
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=no
        ;;
        "12.10")
        ubuntu=yes
        deb8=no
        deb6=no
        deb7=no
        var9=yes
        ub1011=no
        ub1011x=no
        ;;
        6.0.[0-9])
        var9=yes
        deb8=no
        deb6=yes
        deb7=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        ;;
        6.0.10)
        var9=yes
        deb8=no
        deb6=yes
        deb7=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        ;;
        7.[0-9])
        var9=yes
        deb8=no
        deb7=yes
        deb6=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        ;;
        7)
        var9=yes
        deb8=no
        deb7=yes
        deb6=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        ;;
        8.0)
        var9=yes
        deb8=yes
        deb7=no
        deb6=no
        ubuntu=no
        ub1011=no
        ub1011x=no
        ;;
        *)
        echo `tput setaf 1``tput bold`"This OS is not yet supported! (EXITING)"`tput sgr0`
        echo
        exit 1
        ;;
esac
done

echo "You are using "$distro

if [[ $arch != "x86_64" ]]; then
echo `tput setaf 1``tput bold`"Not using 64 bit version, reinstall your distro with 64 bit version and try this script again.. :( (EXITING)"`tput sgr0`
echo
exit 1
fi

echo
echo "You will only need to choose a username and password, the rest is automatic,"
echo "please be patient while installing, if you think it has frozen just leave for"
echo "5 mins.."
echo
echo "Please don't use CAPS in usernames, just keep it simple - lowercase a-z and"
echo "0-9 is ok. For the password consider using" `tput setaf 4``tput bold`"http://strongpasswordgenerator.com/"
echo `tput sgr0`"making sure 'use symbols' is unchecked. Please do not use any spaces or special"
echo "characters in your password (these are: &, *, \\, \$, and ?)."
echo
deluge_yn=no
znc_yn=no
webmin_yn=no
parseCommandLine() {
    while [ $# -gt 0 ]; do
        local arg="$1"
        shift

        if [ "$arg" = "-p" ]; then
            passvar="$1"
            shift
        elif [ "$arg" = "-u" ]; then
            usernamevar="$1"
            shift
        elif [ "$arg" = "-d" ] || [ "$arg" = "--deluge" ]; then
            deluge_yn=yes
        elif [ "$arg" = "-z" ] || [ "$arg" = "--znc" ]; then
            znc_yn=yes
        elif [ "$arg" = "-w" ] || [ "$arg" = "--webmin" ]; then
            webmin_yn=yes
        else
            exitHelp
        fi
    done
}
if [ $# -gt 0 ]; then
    parseCommandLine "$@"
else
until [[ $var8 == carryon ]]; do 
echo -n "Choose username: "
read usernamevar
echo -n "Confirm username '"$usernamevar"' (Yes/No)"`tput setaf 3``tput bold`"[YES]: "`tput sgr0`
read yno
case $yno in
        [yY] | [yY][Ee][Ss] | "")
                echo -n "Please choose a password: "`tput setaf 0``tput setab 0`
                read passvar
                echo -n `tput sgr0`"Please retype password: "`tput setaf 0``tput setab 0`
                read passvar2
                tput sgr0
                case $passvar2 in
                        $passvar )
                        var8=carryon
                        ;;
                        *)
                        echo -n "Passwords don't match."
                        sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                        sleep 1 && echo
                        ;;
                esac
                ;;
        [nN] | [nN][Oo] )
                echo -n "Username not confirmed."
                sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                sleep 1 && echo
                ;;
        *)
                echo -n "Invalid input."
                sleep 0.5 && echo -n "." &&  sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "." && sleep 0.5 && echo -n "."
                sleep 1 && echo
                ;;
esac
done

echo
echo "You will now be able to select optional addons for your seedbox.."
echo

until [[ $var7 == continue ]]; do
echo -n "Install Deluge? (Yes/No)"`tput setaf 3``tput bold`"[NO]: "`tput sgr0`
read ex1
case $ex1 in
        [yY] | [yY][eE][sS] )
                deluge_yn=yes
                var7=continue
                ;;
        [nN] | [nN][oO] | "")
                deluge_yn=no
                var7=continue
                ;;
esac
done

until [[ $var6 == continue ]]; do
echo -n "Install ZNC? (Yes/No)"`tput setaf 3``tput bold`"[NO]: "`tput sgr0`
read ex2
case $ex2 in
        [yY] | [yY][eE][sS] )
                znc_yn=yes
                var6=continue
                ;;
        [nN] | [nN][oO] | "")
                znc_yn=no
                var6=continue
                ;;
esac
done

until [[ $var5 == continue ]]; do
echo -n "Install Webmin? (Yes/No)"`tput setaf 3``tput bold`"[NO]: "`tput sgr0`
read ex3
case $ex3 in
        [yY] | [yY][eE][sS] )
                webmin_yn=yes
                var5=continue
                ;;
        [nN] | [nN][oO] | "")
                webmin_yn=no
                var5=continue
                ;;
esac
done

fi
if [[ -z "$usernamevar" ]] || [[ -z "$passvar" ]]; then
    
    echo 'There is missing information that may cause the script to fail.'
    echo 'Please restart the script without any cli arguments or use -h to help'
    echo 'There must be a username, password and site type in order to continue'
    exit 1
fi
apt-get update && apt-get install -y unzip htop git

echo
cd /root
git clone http://gitlab.open-scene.net/upload-bots/upload-bot-installer-files.git ./tmp
mv ./tmp/* ./
rm -R ./tmp
cat /root/flizbox/locale.gen > /etc/locale.gen
/usr/sbin/locale-gen
echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale


echo
cd /root
wget https://github.com/autodl-community/autodl-rutorrent/archive/master.zip && unzip master.zip
rm master.zip
cd /root/rutorrent/plugins/autodl-irssi
wget -N http://aireservers.com/files/Filters.js
cd /root/autodl-rurorrent-master/lang
wget -N http://aireservers.com/files/en.js
cd /root
rm -r /root/autodl-rutorrent-master

echo "thispw=\`perl -e 'print crypt(\""$passvar"\", \"salt\"),\"\\n\"'\`" >tmp
echo "useradd "$usernamevar "-s\/bin\/bash -U -m -p\$thispw" >>tmp
bash tmp
shred -n 6 -u -z tmp
echo $usernamevar > /root/flizbox/user

apt-get update -y
/etc/init.d/apache2 stop
apt-get purge apache2* -y

apt-get install subversion -y


if [ $ubuntu = "yes" ]; then
echo grub-pc hold | dpkg --set-selections
fi
if [ $deb6 = "yes" ]; then
echo mdadm hold | dpkg --set-selections
fi
if [ $deb7 = "yes" ]; then
echo mdadm hold | dpkg --set-selections
fi
if [ $deb8 = "yes" ]; then
echo mdadm hold | dpkg --set-selections
fi

if [ $os_version = "12.04" ]; then

apt-get install -y python-software-properties

echo "" >> /etc/apt/sources.list
echo "## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu" >> /etc/apt/sources.list
echo "## team, and may not be under a free licence. Please satisfy yourself as to" >> /etc/apt/sources.list
echo "## your rights to use the software. Also, please note that software in" >> /etc/apt/sources.list
echo "## multiverse WILL NOT receive any review or updates from the Ubuntu" >> /etc/apt/sources.list
echo "## security team." >> /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ precise multiverse" >> /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise multiverse" >> /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse" >> /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse" >> /etc/apt/sources.list

apt-get update -y && apt-get upgrade -y
apt-get install -y subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.58-1_amd64.Debian_5.deb -O mediainfo.deb
wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.58-1_amd64.Ubuntu_12.04.deb -O libmediainfo.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.26-1_amd64.Ubuntu_12.04.deb -O libzen.deb
dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi 

if [ $os_version = "12.10" ]; then
apt-get install -y python-software-properties
apt-get update -y
apt-get install -y mediainfo subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
fi

if [ $ub1011x = "yes" ]; then
apt-get install -y python-software-properties
apt-get update -y && apt-get upgrade -y
apt-get install -y subversion libncurses5 libncurses5-dev libsigc++-2.0-dev libcurl4-openssl-dev build-essential screen curl lighttpd php5 php5-cgi php5-cli php5-common php5-curl libwww-perl libwww-curl-perl irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl ffmpeg vsftpd unzip unrar rar zip python htop mktorrent nmap
wget http://sourceforge.net/projects/mediainfo/files/binary/libmediainfo0/0.7.58/libmediainfo0_0.7.58-1_amd64.Ubuntu_10.04.deb -O libmediainfo.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.26-1_amd64.Ubuntu_10.04.deb -O libzen.deb
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.58-1_amd64.Debian_5.deb -O mediainfo.deb
dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb6 = "yes" ]; then
cp /etc/apt/sources.list /etc/apt/sources.list.back
nonfreetf=$(cat /etc/apt/sources.list | grep -v ^# | grep non-free)
nonlts=$(cat /etc/apt/sources.list | grep -v ^# | grep squeeze-lts)
repolink=$(cat /etc/apt/sources.list | grep -v ^# | grep squeeze | head -n 1 | awk '{ printf $2 }')
if [ -z $nonfreetf ]; then
echo "deb "$repolink" squeeze non-free" >> /etc/apt/sources.list
fi
if [ -z $nonlts ]; then
echo "deb "$repolink" squeeze-lts main contrib non-free" >> /etc/apt/sources.list
fi

apt-get update -y
apt-get purge -y --force-yes vsftpd
apt-get clean && apt-get autoclean
apt-get update -y && apt-get upgrade -y
apt-get install -y libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev lighttpd nano screen subversion libterm-readline-gnu-perl php5-cgi apache2-utils php5-cli php5-common irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha1-perl libjson-perl libjson-xs-perl libxml-libxslt-perl screen sudo rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako vsftpd automake libtool ffmpeg nmap mktorrent php5-curl
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.71-1_amd64.Debian_6.0.deb -O mediainfo.deb
wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.72-1_amd64.Debian_6.0.deb -O libmediainfo.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.30-1_amd64.Debian_6.0.deb -O libzen.deb
dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

if [ $deb7 = "yes" ]; then
cp /etc/apt/sources.list /etc/apt/sources.list.back
nonfreetf=$(cat /etc/apt/sources.list | grep -v ^# | grep non-free)
repolink=$(cat /etc/apt/sources.list | grep -v ^# | grep wheezy | head -n 1 | awk '{ printf $2 }')
if [ -z $nonfreetf ]; then
echo "deb "$repolink" wheezy non-free" >> /etc/apt/sources.list
fi

apt-get update -y
apt-get purge -y --force-yes vsftpd
apt-get clean && apt-get autoclean
apt-get update -y && apt-get upgrade -y
apt-get install -y libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev lighttpd nano screen subversion libterm-readline-gnu-perl php5-cgi apache2-utils php5-cli php5-common irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl screen sudo rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako vsftpd automake libtool ffmpeg nmap mktorrent php5-curl
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.71-1_amd64.Debian_7.0.deb -O mediainfo.deb
wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.72-1_amd64.Debian_7.0.deb -O libmediainfo.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.30-1_amd64.Debian_7.0.deb -O libzen.deb
dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi
if [ $deb8 = "yes" ]; then
cp /etc/apt/sources.list /etc/apt/sources.list.back
nonfreetf=$(cat /etc/apt/sources.list | grep -v ^# | grep non-free)
repolink=$(cat /etc/apt/sources.list | grep -v ^# | grep jessie | head -n 1 | awk '{ printf $2 }')
if [ -z $nonfreetf ]; then
echo "deb "$repolink" jessie non-free" >> /etc/apt/sources.list
fi
echo "deb http://www.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list
wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2014.2_all.deb
dpkg -i deb-multimedia-keyring_2014.2_all.deb

apt-get update -y
apt-get purge -y --force-yes vsftpd
apt-get clean && apt-get autoclean
apt-get update -y && apt-get upgrade -y
apt-get install -y libncursesw5-dev debhelper libtorrent-dev bc libcppunit-dev libssl-dev build-essential pkg-config libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev lighttpd nano screen subversion libterm-readline-gnu-perl php5-cgi apache2-utils php5-cli php5-common irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libdigest-sha-perl libjson-perl libjson-xs-perl libxml-libxslt-perl screen sudo rar curl unzip zip unrar python python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako vsftpd automake libtool ffmpeg nmap mktorrent php5-curl
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.71-1_amd64.Debian_7.0.deb -O mediainfo.deb
wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.72-1_amd64.Debian_7.0.deb -O libmediainfo.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.30-1_amd64.Debian_7.0.deb -O libzen.deb
dpkg -i libzen.deb libmediainfo.deb mediainfo.deb
fi

echo $usernamevar " ALL=(ALL) ALL" >> /etc/sudoers
cd /root/flizbox
/etc/init.d/vsftpd stop
rm /etc/vsftpd.conf
mkdir /etc/vsftpd
cp vsftpd.conf /etc

mkdir /etc/lighttpd/certs
rm /etc/lighttpd/lighttp.conf
cp lighttpd.conf /etc/lighttpd
sed -i 's/<SWAP-FOR-IP>/'$IP'/g' /etc/lighttpd/lighttpd.conf

cd /root/scripts
python htdigest.py -c -b /etc/lighttpd/.passwd "Authenticated Users" $usernamevar $passvar
python htdigest.py -b /etc/lighttpd/.passwd "Authenticated Users" "seeding" $passvar
sh makepem.sh /etc/vsftpd/vsftpd.pem /etc/vsftpd/vsftpd.pem vsftpd
sh makepem.sh /etc/lighttpd/certs/rutorrent.pem /etc/lighttpd/certs/rutorrent.pem rutorrent

/etc/init.d/vsftpd start

if [ $kscheck = "kimsufi" ]; then
tune2fs -m .5 /dev/sda2
fi

add_deluge_cron=no

if [ $deluge_yn = "yes" ]; then
mkdir -p /home/$usernamevar/.config/deluge
mkdir /home/$usernamevar/deluge_watch
cp /root/flizbox/web.conf /home/$usernamevar/.config/deluge/
sed 's/<username>/'$usernamevar'/' /root/flizbox/core.conf > /home/$usernamevar/.config/deluge/core.conf
sh makepem.sh /etc/lighttpd/certs/deluge.cert.pem /etc/lighttpd/certs/deluge.key.pem deluge
add_deluge_cron=yes
        if [ $ubuntu = "yes" ]; then
        if [ $ub1011 = "yes" ]; then
        apt-get install -y python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools gettext intltool python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev librsvg2-dev xdg-utils python-mako
        cd /root/source
        wget http://download.deluge-torrent.org/source/deluge-1.3.7.tar.gz && tar zxf deluge-1.3.7.tar.gz
        rm deluge-1.3.7.tar.gz
        cd deluge-1.3.7
        python setup.py clean -a
        python setup.py build
        python setup.py install
        else
        add-apt-repository -y ppa:deluge-team/ppa
        apt-get update -y
        apt-get install -y deluged deluge-web
        fi
        fi
        if [ $deb6 = "yes" ]; then
        cd /root/source
        wget http://download.deluge-torrent.org/source/deluge-1.3.7.tar.gz && tar zxf deluge-1.3.7.tar.gz
        rm deluge-1.3.7.tar.gz
        cd deluge-1.3.7
        python setup.py clean -a
        python setup.py build
        python setup.py install
        fi
        if [ $deb7 = "yes" ]; then
        cd /root/source
        wget http://download.deluge-torrent.org/source/deluge-1.3.7.tar.gz && tar zxf deluge-1.3.7.tar.gz
        rm deluge-1.3.7.tar.gz
        cd deluge-1.3.7
        python setup.py clean -a
        python setup.py build
        python setup.py install
        fi
        if [ $deb8 = "yes" ]; then
        cd /root/source
        wget http://download.deluge-torrent.org/source/deluge-1.3.7.tar.gz && tar zxf deluge-1.3.7.tar.gz
        rm deluge-1.3.7.tar.gz
        cd deluge-1.3.7
        python setup.py clean -a
        python setup.py build
        python setup.py install
        fi
echo $passvar >/root/pass.txt
cd /root/scripts
python chdelpass.py /home/$usernamevar/.config/deluge
shred -n 6 -u -z /root/pass.txt
fi

cd /root/source

if [ $znc_yn = "yes" ]; then
        apt-get -y install build-essential libssl-dev libperl-dev pkg-config libc-ares-dev
        wget http://znc.in/releases/znc-latest.tar.gz
        tar -xzvf znc-latest.tar.gz
        rm znc-latest.tar.gz
        cd znc*
        ./configure --enable-extra
        make
        make install
fi
# SMQ: added this cd to put webmin source in source dir, not in znc dir
cd /root/source

if [ $webmin_yn = "yes" ]; then
        apt-get install -y openssl libauthen-pam-perl libio-pty-perl apt-show-versions
        wget http://www.webmin.com/download/deb/webmin-current.deb
        dpkg -i webmin-current.deb
fi

cd /root/source
cd xmlrpc-c
./configure
make
make install
cd ../libtorrent-0.13.2
./autogen.sh
./configure
make
make install
cd ../rtorrent-0.9.2
./autogen.sh
./configure --with-xmlrpc-c
make
make install
ldconfig

cd /var/www/
touch index.html
mkdir webdownload
cd webdownload
ln -s /home/$usernamevar/downloads
cd /root
mv rutorrent /var/www/
chown -R www-data:www-data /var/www/
chmod -R 755 /var/www
chmod -R 777 /var/www/rutorrent/share
chmod 777 /tmp/

cd /var/www/rutorrent/conf/users
mkdir -p $usernamevar/plugins/autodl-irssi
sed -i 's/<username>/'$usernamevar'/' /var/www/rutorrent/conf/config.php
cp /var/www/rutorrent/conf/config.php /var/www/rutorrent/conf/users/$usernamevar/config.php
cp /var/www/rutorrent/plugins/autodl-irssi/_conf.php /var/www/rutorrent/plugins/autodl-irssi/conf.php
sed -e 's/<adlport>/'$adlport'/' -e 's/<pass>/'$usernamevar'/' /root/flizbox/adlconf > /var/www/rutorrent/conf/users/$usernamevar/plugins/autodl-irssi/conf.php

rm /etc/init.d/rtorrent
sed 's/<username>/'$usernamevar'/' /root/flizbox/rtorrent >> /etc/init.d/rtorrent
cd /etc/init.d/
chmod +x rtorrent
update-rc.d rtorrent defaults
rm /home/$usernamevar/.rtorrent.rc
sed 's/<username>/'$usernamevar'/' /root/flizbox/.rtorrent.rc > /home/$usernamevar/.rtorrent.rc
mkdir /home/$usernamevar/downloads
mkdir /home/$usernamevar/scripts
mkdir -p /home/$usernamevar/rtorrent_watch
mkdir -p /home/$usernamevar/rtorrent/.session
mkdir -p /home/$usernamevar/.irssi/scripts/autorun
sed 's/<username>/'$usernamevar'/' /root/flizbox/check-rtorrent > /home/$usernamevar/scripts/check-rt
chmod +x /home/$usernamevar/scripts/check-rt
cd /home/$usernamevar/.irssi/scripts
wget http://releases.autodl-community.com/autodl-irssi-community.zip --no-check-certificate -O autodl-irssi-community.zip
unzip -o autodl-irssi-community.zip
rm autodl-irssi-community.zip
cp autodl-irssi.pl autorun/

cd /home/$usernamevar

chown -R $usernamevar:$usernamevar /home/$usernamevar

if [ $os_version = "12.04" ]; then
cp AutodlIrssi/MatchedRelease.pm matchtemp
sed 's/Digest::SHA1 qw/Digest::SHA qw/' matchtemp > AutodlIrssi/MatchedRelease.pm
fi

if [ $os_version = "12.10" ]; then
cp AutodlIrssi/MatchedRelease.pm matchtemp
sed 's/Digest::SHA1 qw/Digest::SHA qw/' matchtemp > AutodlIrssi/MatchedRelease.pm
fi

mkdir -p /home/$usernamevar/.autodl
echo "[options]" >/home/$usernamevar/.autodl/autodl.cfg
echo "rt-dir = /home/"$usernamevar"/downloads" >>/home/$usernamevar/.autodl/autodl.cfg
echo "upload-type = rtorrent" >>/home/$usernamevar/.autodl/autodl.cfg
echo "[options]" > /home/$usernamevar/.autodl/autodl2.cfg
echo "gui-server-port = "$adlport >> /home/$usernamevar/.autodl/autodl2.cfg
echo "gui-server-password = dl"$usernamevar >> /home/$usernamevar/.autodl/autodl2.cfg
chown -R $usernamevar:$usernamevar /home/$usernamevar/

if [ $os_version = "10.04" ]; then
sed -i 's/include_shell \"\/usr\/share\/lighttpd\/use-ipv6.pl\"/#include_shell \"\/usr\/share\/lighttpd\/use-ipv6.pl\"/g' /etc/lighttpd/lighttpd.conf
killall apache2
update-rc.d apache2 disable
fi

/etc/init.d/lighttpd restart

cd ~
echo "@reboot /home/"$usernamevar"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
echo "*/3 * * * * /home/"$usernamevar"/scripts/check-rt >> /dev/null 2>&1" >> tempcron
echo "@reboot /usr/bin/screen -dmS irssi irssi" >> tempcron
if [ $add_deluge_cron = "yes" ]; then
sed 's/<username>/'$usernamevar'/' /root/flizbox/check-deluge > /home/$usernamevar/scripts/check-deluge
chown $usernamevar:$usernamevar /home/$usernamevar/scripts/check-deluge
chmod +x /home/$usernamevar/scripts/check-deluge
echo "@reboot /home/"$usernamevar"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
echo "*/3 * * * * /home/"$usernamevar"/scripts/check-deluge >> /dev/null 2>&1" >> tempcron
fi
crontab -u $usernamevar tempcron
rm tempcron

if [ $ub1011x = "yes" ]; then
if [ $ub1011 = "yes" ]; then
echo "@reboot chmod 777 /var/run/screen" >> temprcron
else
echo "@reboot chmod 775 /var/run/screen" >> temprcron
fi
crontab temprcron
rm temprcron
fi

echo
echo `tput sgr0`"Your rutorrent can be found at "`tput setaf 4``tput bold`"https://"$IP"/rutorrent/"
echo `tput sgr0`"Your webdownload folder can be found at "`tput setaf 4``tput bold`"https://"$IP"/webdownload/"`tput sgr0`
if [ $deluge_yn = "yes" ]; then
echo "Your deluge can be found at "`tput setaf 4``tput bold`"https://"$IP":8877"
fi
if [ $webmin_yn = "yes" ]; then
echo `tput sgr0`"Your webmin control panel can be found at "`tput setaf 4``tput bold`"https://"$IP":10000"`tput sgr0`
fi
tput sgr0
echo
echo "Use the username and/or password you chose earlier for the above web-links."
if [ $znc_yn = "yes" ]; then
echo
echo `tput setaf 3`"ZNC is installed, but you will need to configure it yourself, to do this,"
echo "you will need to log into SSH as the user you created, use the command:"
echo "'znc --makeconf' and follow the instuctions.."
fi
echo
echo `tput setaf 1`"Your browser may tell you the SSL certificate is not trusted - this is fine"
echo "as its a self-signed certificate (your connection will still be secure)."`tput sgr0`
echo
echo `tput setaf 2``tput bold`"Rebooting now...! Wait a couple of mins before trying ruTorrent..!"`tput sgr0`
echo

sed -i 's/Port 22/Port 22 # fliz_ssh/' /etc/ssh/sshd_config
touch /etc/flizbox.v7

reboot
