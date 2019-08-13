#!/bin/sh

case $1 in

	deconfig)
		ip addr flush dev $interface
	;;

	renew|bound)
		ip addr add $ip/$mask dev $interface

		for i in $router; do
			route add default gw $i dev $interface
		done

		truncate -s 0 /System/Settings/resolv.conf

		if [ -n "$domain" ]; then
			echo "search $domain" >> /System/Settings/resolv.conf
		fi

		for i in $dns; do
			echo "nameserver $i" >> /System/Settings/resolv.conf
		done
	;;
esac
