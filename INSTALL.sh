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
mana_version="2017-01-13"
MANA="https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/hostapd-mana_"$mana_version"_ar71xx.ipk"
ASLEAP="https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/asleap_2.2-1_ar71xx.ipk"
#
echo -e "${RED}Installing: ${NC}MANA-Toolkit."
echo -e "Go grab a cup of coffee, this can take a little while...\n"
# Download installation-files to temporary directory, and then update OPKG repositories.
cd /tmp
opkg update
wget "$ASLEAP"
wget "$MANA"
#
# Creating sym-link between python-directories located on the sd-card and internally.
# The main-directory will be located on the sd-card (/sd)
# This will only happen on the Pineapple NANO.
if [ -e /sd ]; then
	# sym-link & nano install
	rm -r /usr/lib/python2.7
	mkdir -p /sd/usr/lib/python2.7
	ln -s /sd/usr/lib/python2.7 /usr/lib/python2.7
	opkg --dest sd --force-overwrite install asleap_2.2-1_ar71xx.ipk hostapd-mana_"$mana_version"_ar71xx.ipk
else
	# Tetra installation / general install.
	opkg --force-overwrite install asleap_2.2-1_ar71xx.ipk hostapd-mana_"$mana_version"_ar71xx.ipk
fi
# Cleanup
rm hostapd-mana_"$mana_version"_ar71xx.* asleap_2.2-1_ar71xx.*
echo -e "${RED}Installation completed!"
echo -e "${NC}Launch MANA by typing: '${RED}launch-mana' ${NC}in the terminal."
exit 0
