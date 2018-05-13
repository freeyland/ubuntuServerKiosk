#!/bin/bash

# Define colors
red='\e[0;31m'
green='\e[1;32m'
blue='\e[1;36m'
NC='\e[0m' # No color

clear


# Determine Ubuntu Version Codename
VERSION=$(lsb_release -cs)

# Check if stages.cfg exists. If not, created it. 
if [ ! -f stages.cfg ]
then
echo 'updates_installed=0
grub_recovery_disable=0
wireless_enabled=0
xorg_installed=0
admin_created=0
kiosk_created=0
kiosk_autologin=0
screensaver_installed=0
chromium_installed=0
kiosk_scripts=0
mplayer_installed=0
touchscreen_installed=0
audio_installed=0
additional_software_installed=0
crontab_installed=0
prevent_sleeping=0
ossh_installed=0
kiosk_permissions=0
immagemagick_installed=0
openvpn_installed=0' > stages.cfg
fi

# Import stages config
. stages.cfg




echo -e "${red}Installing operating system updates ${blue}(this may take a while)${red}...${NC}"
if [ "$updates_installed" == 0 ]
then
# Use mirror method
# sed -i "1i \
# deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION main restricted universe multiverse\n\
# deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-updates main restricted universe multiverse\n\
# deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-backports main restricted universe multiverse\n\
# deb mirror://mirrors.ubuntu.com/mirrors.txt $VERSION-security main restricted universe multiverse\n\
# " /etc/apt/sources.list

# Refresh
sudo apt-get -y update        # Fetches the list of available updates
sudo apt-get -y dist-upgrade  # Installs updates (new ones)
sudo apt-get -y upgrade       # Strictly upgrades the current packages


# Clean
apt-get -q=2 autoremove
apt-get -q=2 clean
sed -i -e 's/updates_installed=0/updates_installed=1/g' stages.cfg
clear
echo -e "${red}Installing operating system updates... ${NC}"
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Updates already installed. Skipping...${NC}"
fi

read -p "Press any key to continue... ${NC}" -n1 -s

echo -e "${red}Installing a graphical user interface...${NC}"
if [ "$xorg_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends xorg matchbox-window-manager > /dev/null
apt-get -q=2 install --no-install-recommends nodm
read -p "Press any key to continue... " -n1 -s

echo -e "${red}Installing openssh...${NC}"
if [ "$ossh_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends openssh-server > /dev/null
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/sshd_config -O /etc/ssh/sshd_config
fi

read -p "Press any key to continue... ${NC}" -n1 -s

# Hide Cursor
apt-get -q=2 install --no-install-recommends unclutter > /dev/null
# Install monit
apt-get -q=2 install --no-install-recommends monit > /dev/null


sed -i -e 's/xorg_installed=0/xorg_installed=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}Xorg already installed. Skipping...${NC}"
fi

read -p "Press any key to continue... ${NC}" -n1 -s


# Prevent sleeping for inactivity
echo -e "${red}Prevent sleeping for inactivity...${NC}"
if [ "$prevent_sleeping" == 0 ]
then
mkdir /etc/kbd
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/config -O /etc/kbd/config
sed -i -e 's/prevent_sleeping=0/prevent_sleeping=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Prevent sleeping already done. Skipping...${NC}"
fi

read -p "Press any key to continue... ${NC}" -n1 -s


echo -e "${red}Disabling root recovery mode...${NC}"
if [ "$grub_recovery_disable" == 0 ]
then
#ssed -i -e 's/#GRUB_DISABLE_RECOVERY/GRUB_DISABLE_RECOVERY/g' /etc/default/grub
sed -i -e 's/GRUB_DISTRIBUTOR=`lsb_release -i -s 2> \/dev\/null || echo Debian`/GRUB_DISTRIBUTOR=Kiosk/g' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=4/g' /etc/default/grub
sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="video=efifb fbcon=rotate:3"/g' /etc/default/grub
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/g' /etc/default/grub
update-grub
sed -i -e 's/grub_recovery_disable=0/grub_recovery_disable=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}Root recovery already disabled. Skipping...${NC}"
fi

read -p "Press any key to continue... ${NC}" -n1 -s

echo -e "${red}Creating kiosk user...${NC}"
if [ "$kiosk_created" == 0 ]
then
useradd kiosk -m -d /home/kiosk -p `openssl passwd -crypt K10sk` -s /bin/bash
sed -i -e 's/kiosk_created=0/kiosk_created=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Kiosk already created. Skipping...${NC}"
fi

read -p "Press any key to continue... ${NC}" -n1 -s

# Configure kiosk autologin
echo -e "${red}Configuring kiosk autologin...${NC}"
if [ "$kiosk_autologin" == 0 ]
then
sed -i -e 's/NODM_ENABLED=false/NODM_ENABLED=true/g' /etc/default/nodm
sed -i -e 's/NODM_USER=root/NODM_USER=kiosk/g' /etc/default/nodm
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/nodm -O /etc/init.d/nodm
sed -i -e 's/kiosk_autologin=0/kiosk_autologin=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Kiosk autologin already configured. Skipping...${NC}"
fi
	

read -p "Press any key to continue... " -n1 -s


# Install Chromium browser
echo -e "${red}Installing ${blue}Chromium${red} browser...${NC}"
if [ "$chromium_installed" == 0 ]
then
echo "
# Ubuntu Partners
deb http://archive.canonical.com/ $VERSION partner
"  >> /etc/apt/sources.list
apt-get -q=2 update
apt-get -q=2 -y install --force-yes chromium-browser > /dev/null
#apt-get -q=2 install flashplugin-installer > /dev/null # flash
sed -i -e 's/chromium_installed=0/chromium_installed=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}Chromium already installed. Skipping...${NC}"
fi


read -p "Press any key to continue..." -n1 -s

# Kiosk scripts
echo -e "${red}Creating Kiosk Scripts...${NC}"
if [ "$kiosk_scripts" == 0 ]
then
mkdir /home/kiosk/.kiosk

read -p "Press any key to continue..." -n1 -s

# Create other kiosk scripts
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/configs/browser.cfg -O /home/kiosk/.kiosk/browser.cfg
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/killchromium.sh -O /home/kiosk/killchromium.sh
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/configs/monitrc -O /etc/monit/monitrc
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/configs/browser_switches.cfg -O /home/kiosk/.kiosk/browser_switches.cfg
chmod 777 /home/kiosk/.kiosk/browser.cfg

# Create browser killer
apt-get -q=2 install --no-install-recommends xprintidle > /dev/null
chmod +x /home/kiosk/.kiosk/browser_killer.sh
sed -i -e 's/kiosk_scripts=0/kiosk_scripts=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Kiosk scripts already installed. Skipping...${NC}"
fi


read -p "Press any key to continue... " -n1 -s


echo -e "${red}Installing touchscreen support...${NC}"
if [ "$touchscreen_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends xserver-xorg-input-multitouch xinput-calibrator > /dev/null
sed -i -e 's/touchscreen_installed=0/touchscreen_installed=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Touchscreen support already installed. Skipping...${NC}"
fi


read -p "Press any key to continue... " -n1 -s

echo -e "${red}Installing audio...${NC}"
if [ "$audio_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends alsa > /dev/null
adduser kiosk audio
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/asoundrc -O /home/kiosk/.asoundrc
chown kiosk.kiosk /home/kiosk/.asoundrc
sed -i -e 's/audio_installed=0/audio_installed=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}Audio already installed. Skipping...${NC}"
fi

echo -e "${red}Installing ImageMagick...${NC}"
if [ "$immagemagick_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends imagemagick > /dev/null
sed -i -e 's/immagemagick_installed=0/immagemagick_installed=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}ImageMagick already installed. Skipping...${NC}"
fi

echo -e "${red}Installing OpenVPN...${NC}"
if [ "$openvpn_installed" == 0 ]
then
apt-get -q=2 install --no-install-recommends openvpn > /dev/null
sed -i -e 's/openvpn_installed=0/openvpn_installed=1/g' stages.cfg
echo -e "\n${green}Done!${NC}"
else
	echo -e "${blue}OpenVPN already installed. Skipping...${NC}"
fi

read -p "Press any key to continue..." -n1 -s

echo -e "${red}Installing 3rd party software...${NC}"
if [ "$additional_software_installed" == 0 ]
then
apt-get -q=2 install pulseaudio > /dev/null
apt-get -q=2 install libvdpau* > /dev/null
apt-get -q=2 install alsa-utils > /dev/null
apt-get -q=2 install mc > /dev/null

wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/default.pa -O /etc/pulse/default.pa
sed -i -e 's/additional_software_installed=0/additional_software_installed=1/g' stages.cfg
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}3rd party software already installed. Skipping...${NC}"
fi

read -p "Press any key to continue..." -n1 -s

# Crontab for fixing hdmi sound mute problem
# if [ "$crontab_installed" == 0 ]
# then
# echo -e "${red}Crontab for fixing hdmi sound mute problem${NC}"
# echo "* * * * * /usr/bin/amixer set IEC958 unmute" > cron
# crontab -l -u kiosk | cat - cron | crontab -u kiosk -
# rm -rf cron
# service cron restart
# sed -i -e 's/crontab_installed=0/crontab_installed=1/g' stages.cfg
# echo -e "${green}Done!${NC}"
# else
# 	echo -e "${blue}Crontab already installed. Skipping...${NC}"
# fi

#echo -e "${red}Installing inocron...${NC}"
#if [ "$crontab_installed" == 0 ]
#then
#	apt-get -q=2 install --no-install-recommends inocron > /dev/null
#	wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/incron.allow -O /etc/incron.allow
#	echo "/home/kiosk/.kiosk/browser.cfg IN_MODIFY sudo reboot" > incron
#	#here we contactenate (cat) the current content from incrontab with the content of previously created incron file
#	incrontab -l | cat - incron | incrontab -
#	rm -rf incron
#	sed -i -e 's/crontab_installed=0/crontab_installed=1/g' stages.cfg
#	echo -e "${green}Done!${NC}"
#else
#	echo -e "${blue}Crontab already installed. Skipping...${NC}"
#fi


# Set correct user and group permissions for /home/kiosk
echo -e "${red}Set correct user and group permissions for ${blue}/home/kiosk${red}...${NC}"
if [ "$kiosk_permissions" == 0 ]
then
chown -R kiosk.kiosk /home/kiosk/
sed -i -e 's/kiosk_permissions=0/kiosk_permissions=1/g' stages.cfg
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/sudoers -O /etc/sudoers
echo -e "${green}Done!${NC}"
else
	echo -e "${blue}Permissions already set. Skipping...${NC}"
fi


read -p "Press any key to continue..." -n1 -s

# Create xsession
wget -q https://raw.githubusercontent.com/freeyland/ubuntuServerKiosk/master/scripts/xsession -O /home/kiosk/.xsession

# Choose kiosk name
kiosk_name=""
while [[ ! $kiosk_name =~ ^[A-Za-z0-9]+$ ]]; do
    echo -e "${green}Provide kiosk name (e.g. kiosk1):${NC}"
    read kiosk_name
done

old_hostname="$( hostname )"

if [ -n "$( grep "$old_hostname" /etc/hosts )" ]; then
    sed -i "s/$old_hostname/$kiosk_name/g" /etc/hosts
else
    echo -e "$( hostname -I | awk '{ print $1 }' )\t$kiosk_name" >> /etc/hosts
fi

sed -i "s/$old_hostname/$kiosk_name/g" /etc/hostname
echo -e "${blue}Kiosk hostname set to: ${kiosk_name}${NC}"


echo -e "${green}Reboot?${NC}"
echo "Do you wish to reboot?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) make install; break;
        No ) exit;
    esac
done;;
esac
