#!/bin/bash
#
# Installation script for MANA-Toolkit, for the Pineapple NANO and TETRA.
#
# The main directory will be on the SD-card
# This will only happen on the Pineapple NANO
# Starting MANA-Toolkit Install.
#
# Download installation-files to temporary directory.
cd /tmp
opkg update
wget https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/asleap_2.2-1_ar71xx.ipk
wget https://github.com/adde88/hostapd-mana-openwrt/raw/master/bin/ar71xx/packages/base/hostapd-mana_2017-01-13_ar71xx.ipk
#
# Creating sym-link between python-directories located on the sd-card and internally.
# The main-directory will be located on the sd-card (/sd)
# This will only happen on the Pineapple NANO.
if [ -e /sd ]; then
	# sym-link & nano install
	rm -r /usr/lib/python2.7
	mkdir -p /sd/usr/lib/python2.7
	ln -s /sd/usr/lib/python2.7 /usr/lib/python2.7
	opkg --dest sd --force-overwrite install asleap_2.2-1_ar71xx.ipk hostapd-mana_2017-01-13_ar71xx.ipk
else
	# Tetra installation / general install.
	opkg --force-overwrite install asleap_2.2-1_ar71xx.ipk hostapd-mana_2017-01-13_ar71xx.ipk
fi
exit 0
