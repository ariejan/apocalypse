#!/bin/bash

# Apocalypse Monitoring
# (C) 2011 Ariejan de Vroom, Kabisa ICT

APOCALYPSE_HOST='127.0.0.1:3000'
APOCALYPSE_HOST_ID='CHANGEME'

LOADAVG=$(cat /proc/loadavg)
MEMINFO=$(cat /proc/meminfo)
CPUINFO=$(cat /proc/cpuinfo)
DISK_RAW_DATA=$(iostat -dk | tail -n+4)
DISK_USAGE_DATA=$(df --block-size=M)
NET_RAW_DATA=$(ifconfig)
CPU_CORE_COUNT=$(cat /proc/cpuinfo | grep bogomips | wc -l)
NET_INTERFACES=$(ifconfig | egrep Link\ encap | awk '{print $1}')
NET_DEV_COUNT=$(echo "$NET_INTERFACES" | wc -l)

YAML_NETIO=""
for IFACE in $NET_INTERFACES; do	
if [ $IFACE != 'lo' ] ; then
  YAML_NETIO=$YAML_NETIO"    $IFACE:
      hwaddr: \""$(ifconfig $IFACE | egrep -o HWaddr\ \([0-9a-fA-F]\{2\}\:*\){6} | awk '{print $2}')"\"
      mtu: "$(ifconfig $IFACE | egrep -o MTU\:[0-9]+ | tr -s ':' ' ' | awk '{print $2}')"
      metric: "$(ifconfig $IFACE |	egrep -o Metric\:[0-9]+ | tr -s ':' ' ' | awk '{print $2}')"
      encapsulation: \""$(ifconfig $IFACE | egrep -o Link\ encap\:[a-zA-Z]+ | cut -d":" -f2 )"\"
      rxbytes: "$(ifconfig $IFACE | grep bytes | awk '/RX/ {print $2}' | tr -s ':' ' ' | awk '{print $2}')"
      txbytes: "$(ifconfig $IFACE | grep bytes | awk '/TX/ {print $6}' | tr -s ':' ' ' | awk '{print $2}')"
      ipv4address: \""$(ifconfig $IFACE | egrep -o inet\ addr\:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} | tr -s ':' ' ' | awk '{print $3}')"\"
      broadcast: \""$(ifconfig $IFACE | egrep -o Bcast\:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} | tr -s ':' ' ' | awk '{print $2}')"\"
      netmask: \""$(ifconfig $IFACE | egrep -o Mask\:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\} | tr -s ':' ' ' | awk '{print $2}')"\"
      gateway: \""$(netstat -rn | grep ^0.0.0.0 | grep UG | grep $IFACE | awk '{print $2}' | head -n1)"\"
      ipv6addr: \""$(ifconfig $IFACE | egrep -o inet6\ addr\:\ \([a-fA-F0-9]\{1,4}\:\{1,2\}[a-fA-F0-9]\{1,4}\:\{1,2\}\)+[A-Fa-f0-9\/^\ ]+ | awk '{print $3}')"\"
      ipv6scope: \""$(ifconfig $IFACE | egrep -o Scope\:[a-zA-Z]+ | cut -d":" -f2)"\"
"
fi
done

YAML_DISKIO="";
for DISK in $(echo "$DISK_RAW_DATA" | awk '{print $1}'); do
	YAML_DISKIO=$YAML_DISKIO"    $DISK:
      rps: "$(echo "$DISK_RAW_DATA" | egrep ^$DISK | awk '{print $3}')"
      tps: "$(echo "$DISK_RAW_DATA" | egrep ^$DISK | awk '{print $2}')"
      wps: "$(echo "$DISK_RAW_DATA" | egrep ^$DISK | awk '{print $4}')"
      size: "$(echo "$DISK_USAGE_DATA" | egrep \/dev\/$DISK | awk '{print $2}' | tr -d 'M')"
      used: "$(echo "$DISK_USAGE_DATA" | egrep \/dev\/$DISK | awk '{print $3}' | tr -d 'M')"
      available: "$(echo "$DISK_USAGE_DATA" | egrep \/dev\/$DISK | awk '{print $4}' | tr -d 'M')"
      usage: "$(echo "$DISK_USAGE_DATA" | egrep \/dev\/$DISK | awk '{print $5}' | tr -d '%')"
      mount_point: \""$(echo "$DISK_USAGE_DATA" | egrep \/dev\/$DISK | awk '{print $6}')"\"
"
done

YAMLDATA="metrics:
  timestamp: \""$(date --rfc-2822 -u)"\"
  cpu:
    coreCount: "$(echo $CPU_CORE_COUNT)"
    loadavg: ["$(echo $LOADAVG | tr -s ' ' ',' | tr -s '/' ',')"]
  memory:
    free: $(echo "$MEMINFO" | grep MemFree | awk '{print $2}')
    total: $(echo "$MEMINFO" | grep MemTotal | awk '{print $2}')
  swap:
    free: $(echo "$MEMINFO" | grep SwapFree | awk '{print $2}')
    total: $(echo "$MEMINFO" | grep SwapTotal | awk '{print $2}')
  disks:
"$YAML_DISKIO"  network:
"$YAML_NETIO"
"

APOCALYPSE_RESULT=$(wget --post-data=$YAMLDATA --header='Content-type:text/yaml' -q -O- http://$APOCALYPSE_HOST/api/metrics/$APOCALYPSE_HOST_ID)

echo $APOCALYPSE_RESULT
