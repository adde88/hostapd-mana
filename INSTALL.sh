#!/bin/bash
#
# Installation script for MANA-Toolkit, for the Pineapple NANO and TETRA.
# Written by: Andreas Nilsen - adde88@gmail.com - https://www.github.com/adde88
#
# Starting MANA-Toolkit Install.
#
# Variables and colors.
RED='\033[0;31m'
NC='\033[0m'
MANA=`grep -F "hostapd-mana_" /tmp/ManaToolkit/base | awk {'print $5'} | awk -F'"' {'print $2'}`
ASLEAP=`grep -F "asleap_" /tmp/ManaToolkit/base | awk {'print $5'} | awk -F'"' {'print $2'}`
#
echo -e "${RED}Installing: ${NC}MANA-Toolkit."
echo -e "Go grab a cup of coffee, this will take a while...\n"
# Download installation-files to temporary directory, and then update OPKG repositories.
cd /tmp
opkg update
wget "https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/"$ASLEAP""
wget "https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/"$MANA""
#
# Creating sym-link between python-directories located on the sd-card and internally.
# The main-directory will be located on the sd-card (/sd)
# This will only happen on the Pineapple NANO.
if [ -e /sd ]; then
	# sym-link & nano install
	opkg --dest sd --force-overwrite install "$ASLEAP" "$MANA" sslsplit
	ln -s /sd/etc/mana-toolkit /etc/mana-toolkit
else
	# Tetra installation / general install.
	opkg --force-overwrite install "$ASLEAP" "$MANA" sslsplit
fi
# Cleanup
rm -f "$ASLEAP" "$MANA"
# Disable stunnel init-script at boot.
/etc/init.d/stunnel disable
echo -e "${RED}Installation completed!"
echo -e "${NC}Type: ${RED}'install-mana-depends' ${NC}to install python-related dependencies."
echo -e "${NC}Launch MANA by typing: '${RED}launch-mana' ${NC}in the terminal."
# Let's set the default interface
uci set ManaToolkit.run.interface="wlan1"
uci commit ManaToolkit.run.interface
exit 0
