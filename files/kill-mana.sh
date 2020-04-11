#!/bin/sh
#2017 - Zylla / adde88@gmail.com

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

MYTIME=`date +%d-%m-%Y`
MYTIME_HR=`date +%H:%M:%S`
PHY=`uci get ManaToolkit.run.interface`

mana_output_file="/pineapple/modules/ManaToolkit/log/hostapd-mana_output.log"

mana_pid=`pgrep hostapd-mana`
sslstrip_pid=`pgrep -f sslstrip2`
sslsplit_pid=`pgrep -f sslsplit`
dns2proxy_pid=`pgrep -f dns2proxy`
dnsmasq_pid=`pgrep -f "/etc/hostapd-mana/dnsmasq-dhcpd.conf"`
netcreds_pid=`pgrep -f net-creds`

if [ "$dnsmasq_pid" != "" ];then
	kill -9 "$dnsmasq_pid"
fi
if [ "$mana_pid" != "" ];then
	mkdir -p /pineapple/modules/ManaToolkit/log/hostapd-mana/${MYTIME}
	kill -9 "$mana_pid"
	mv "$mana_output_file" /pineapple/modules/ManaToolkit/log/hostapd-mana/${MYTIME}/output_${MYTIME_HR}.log
fi
if [ "$sslstrip_pid" != "" ];then
	mkdir -p /pineapple/modules/ManaToolkit/log/SSLStrip+/${MYTIME}
	kill -9 "$sslstrip_pid"
	mv /pineapple/modules/ManaToolkit/log/SSLStrip+/sslstrip.log /pineapple/modules/ManaToolkit/log/SSLStrip+/${MYTIME}/sslstrip_${MYTIME_HR}.log
fi
if [ "$sslsplit_pid" != "" ];then
	mkdir -p /pineapple/modules/ManaToolkit/log/SSL-Split/${MYTIME}
	kill -9 "$sslsplit_pid"
	mv /pineapple/modules/ManaToolkit/log/SSL-Split/sslsplit-connect.log /pineapple/modules/ManaToolkit/log/SSL-Split/${MYTIME}/connect_${MYTIME_HR}.log
	mv /pineapple/modules/ManaToolkit/log/SSL-Split/*/*.log /pineapple/modules/ManaToolkit/log/SSL-Split/${MYTIME}/
fi
if [ "$dns2proxy_pid" != "" ];then
	kill -9 "$dns2proxy_pid"
fi
if [ "$netcreds_pid" != "" ];then
	mkdir -p /pineapple/modules/ManaToolkit/log/Net-Creds/${MYTIME}
	kill -9 "$netcreds_pid"
	mv /pineapple/modules/ManaToolkit/log/Net-Creds/net-creds.log /pineapple/modules/ManaToolkit/log/Net-Creds/${MYTIME}/net-creds_${MYTIME_HR}.log
fi

ifconfig "$PHY" down
ifconfig "$PHY" up
