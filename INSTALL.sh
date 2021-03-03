#!/bin/bash
#
# Installation script for hostapd-mana, for the Pineapple NANO and TETRA.
# Written by: Andreas Nilsen - adde88@gmail.com - https://www.github.com/adde88
#
# Variables and colors.
RED='\033[0;31m'
NC='\033[0m'
#
mkdir -p /tmp/ManaToolkit
wget https://github.com/adde88/hostapd-mana-openwrt/tree/openwrt-19.07/bin/packages/mipsel_24kc/custom -P /tmp/ManaToolkit 2&>1 >/dev/null
MANA=`grep -F "hostapd-mana_" /tmp/ManaToolkit/custom | awk {'print $8'} | awk -F'"' {'print $2'} | grep mipsel_24kc`
ASLEAP=`grep -F "asleap_" /tmp/ManaToolkit/custom | awk {'print $8'} | awk -F'"' {'print $2'} | grep mipsel_24kc`
#
echo -e "${RED}Installing: ${NC}hostapd-mana."
echo -e "Go grab a cup of coffee, this will take a while...\n"
# Download installation-files to temporary directory, and then update OPKG repositories.
cd /tmp
opkg update
wget "https://github.com/adde88/hostapd-mana-openwrt/raw/openwrt-19.07/bin/packages/mipsel_24kc/custom/"$ASLEAP"" 2&>1 >/dev/null
wget "https://github.com/adde88/hostapd-mana-openwrt/raw/openwrt-19.07/bin/packages/mipsel_24kc/custom/"$MANA"" 2&>1 >/dev/null
#
# Creating sym-link between python-directories located on the sd-card and internally.
# The main-directory will be located on the sd-card (/sd)
# This will only happen on the Pineapple NANO.
if [ -e /sd ]; then
	# sym-link & nano install
	opkg --dest sd --force-overwrite install "$ASLEAP" "$MANA" sslsplit
	ln -s /sd/etc/hostapd-mana /etc/hostapd-mana
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
echo -e "${NC}Launch hostapd-mana by typing: '${RED}launch-mana' ${NC}in the terminal.\n"
echo -e "${RED}WARNING: ${NC}This script has not been updated for the Pineapple MK7 yet! And will most likely fail on this device!"
# Let's set the default interface
uci set ManaToolkit.run.interface="wlan0"
uci commit ManaToolkit.run.interface
exit 0
