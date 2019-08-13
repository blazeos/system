#!/bin/sh

if [ $2 == "CONNECTED" ] && [ "$IF_WIRELESS" == "dhcp" ]; then
	udhcpc -S -b -i $1 -p /System/State/run/udhcpc-$1.pid
fi

if [ $2 == "DISCONNECTED" ] && [ -f "/System/State/run/udhcpc-$1.pid" ]; then
	kill $(cat /System/State/run/dhcpc-$1.pid)
	kill $(cat /System/State/run/wpa_supplicant-$1.pid)
fi
