#!/bin/bash
# vars
pkill hostapd-mana
pkill dnsmasq
RED='\033[0;31m'
NC='\033[0m'
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf

# Checks for a working internet connection by ping
if ping -c 1 google.com >> /dev/null 2>&1; then
	echo -e "Pineapple seems to be: ${RED}ONLINE${NC}."
	upstream=br-lan
	phy=wlan1
	conf=/etc/mana-toolkit/hostapd-mana.conf
	dhcp_conf=/etc/mana-toolkit/dnsmasq-dhcpd.conf

	# Setup interface and forward traffic
	echo '1' > /proc/sys/net/ipv4/ip_forward
	ip addr flush dev $phy
	ip addr add 10.0.0.1/24 dev $phy
	ip link set $phy up
	ip route add default via 10.0.0.1 dev $phy

	# Starting MANA and DHCP server
	sed -i "s/^interface=.*$/interface=$phy/" $conf
	hostapd-mana $conf &
	dnsmasq -z -C $dhcp_conf -i $phy -I lo

	# Add fking rule to table 1006
	for table in $(ip rule list | awk -F"lookup" '{print $2}');
	do
	DEF=`ip route show table $table|grep default|grep $upstream`
	if ! [ -z "$DEF" ]; then
		break
	fi
	done
	ip route add 10.0.0.0/24 dev $phy scope link table $table

	# Save iptables
	iptables-save > /tmp/rules.txt
	# Flush
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -F -t nat
	# Masquerade
	iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
	iptables -A FORWARD -i $phy -o $upstream -j ACCEPT
	iptables -t nat -A PREROUTING -i $phy -p udp --dport 53 -j DNAT --to 10.0.0.1

	echo -e "MANA has ${RED}started${NC} successfully! Press enter to kill it properly"
	read
	pkill dnsmasq
	pkill hostapd-mana
	# Restore
	iptables-restore < /tmp/rules.txt
	rm /tmp/rules.txt
	# Remove iface and routes
	ip addr flush dev $phy
	ip link set $phy down
else
	echo -e "Pineapple seems to be: ${RED}OFFLINE${NC}."
	echo -e "MANA has been ${RED}stopped${NC}."
	exit 0
fi
