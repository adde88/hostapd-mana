This repo. contains a patched version of hostapd-mana, that will run on OpenWRT Chaos Calmer (ar71xx)
The OpenWRT Makefile is located at this repo: https://github.com/adde88/hostapd-mana-openwrt

My main goal was to get it working for the 6.th gen. Wifi Pineapple NANO, and TETRA, and IT DOES!
IPK file is here: https://github.com/adde88/hostapd-mana-openwrt/blob/master/bin/ar71xx/packages/base/hostapd-mana_2016-09-16_ar71xx.ipk

Update: 16.09.2016:
This will install hostapd-mana on your pineapple nano and tetra.
config files are located: /etc/mana-toolkit
and the scripts are at: /usr/share/mana-toolkit/

The main script to init. everything is /usr/share/mana-toolkit/mana-pineapple.sh

The repo. also contains IPK+src files for asleap, sslstrip, dns2proxy, and the complete MANA package.
BUT the current script does NOT start sslstrip+dns2proxy...
It should run, but i haven't gotten around to testing it yet.
As my main goal was to build hostapd-mana for the pineapple, the rest should be a smooth ride. :)

Yours truly, Andreas Nilsen! - @adde88

================
HOSTAPD-MANA made by Dominic White (singe) & Ian de Villiers @ sensepost (research@sensepost.com)

Overview
--------
A access point (evilAP) first presented at Defcon 22.

More specifically, it contains the improvements to KARMA attacks we implemented into hostapd, as well as the ability to rogue EAP access points.

This will track the hostapd releases, although at a somewhat lagged pace depending on time. At the time of publication this was up to date with the latest hostapd-2.3 branch.

Contents
--------

It contains:
* hostapd-mana - modified hostapd that implements our new karma attacks
* crackapd - a tool for offloading the cracking of EAP creds to an external tool and re-adding them to the hostapd EAP config (auto crack 'n add)

Installation
------------

The build instructions are exactly the same as hostapd's, and can be found in hostapd/README

Pre-Requisites
--------------

_Hardware_

You'll need a wifi card that supports master mode. You can check whether it does by running:
    iw list
You want to see "AP" in the output. Something like:
```
Supported interface modes:
         * IBSS
         * managed
         * AP
         * AP/VLAN
         * monitor
         * mesh point
```
More information at https://help.ubuntu.com/community/WifiDocs/MasterMode#Test_an_adapter_for_.22master_mode.22

Three cards that have been confirmed to work well, in order of preference are:
* Ubiquiti SR-71 (not made anymore :(, chipset AR9170, driver carl9170 http://wireless.kernel.org/en/users/Drivers/carl9170 ) 
* Alfa Black AWUS036NHA (chipset Atheros AR9271, buy at http://store.rokland.com/products/alfa-awus036nha-802-11n-wireless-n-usb-wi-fi-adapter-2-watt ) 
* TP-Link TL-WN722N (chipset Atheros AR9271 )

Note, the silver Alfa does not support master mode and will not work.

Running
-------

You'll need to generate a valid configuration file. Some example of these are included in the MANA toolkit at https://github.com/sensepost/mana

License
-------

The patches included in hostapd-mana by SensePost are licensed under a Creative Commons Attribution-ShareAlike 4.0 International License (http://creativecommons.org/licenses/by-sa/4.0/) Permissions beyond the scope of this license may be available at http://sensepost.com/contact us/. hostapd's code retains it's original license available in COPYING.
