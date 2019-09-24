#!/bin/sh

if [ ! -d "/sys/class/gpio/gpio45" ]
then
	echo 45 > /sys/class/gpio/export
	echo out  > /sys/class/gpio/gpio45/direction
	echo 0 > /sys/class/gpio/gpio45/value
fi

if [ ! -d "/sys/class/gpio/gpio46" ]
then
	echo 46 > /sys/class/gpio/export
	echo out  > /sys/class/gpio/gpio46/direction
	echo 0 > /sys/class/gpio/gpio46/value
fi

if [ $# -eq 1 ]
then
	if [ $1 == "on" ]
	then
		echo 1 > /sys/class/gpio/gpio45/value
		echo "7601-1 ON"
		echo 1 > /sys/class/gpio/gpio46/value
		echo "7601-2 ON"
	elif [ $1 = "off" ]
	then
		echo 0 > /sys/class/gpio/gpio45/value
		echo "7601-1 OFF"
		echo 0 > /sys/class/gpio/gpio46/value
		echo "7601-2 OFF"
	else
		echo "Usage:"
		echo "	7601_test.sh on/off		-----Enable/Disable two 7601 "
		echo "	7601_test.sh 45/46 on/off	------Enable/Disable one 7601"
		echo ""
	fi		
elif [ $# -eq 2 ]
then
	if [ $1 == "45" ]
	then
		if [ $2 == "on" ]
		then
			echo 1 > /sys/class/gpio/gpio45/value
			echo "7601-1 ON"
		elif [ $2 == "off" ]
		then
			echo 0 > /sys/class/gpio/gpio45/value
			echo "7601-1 OFF"
		elif [ $2 == "test" ]
		then
			uci set network.wwan=interface
			uci set network.wwan.proto='dhcp'
			uci set network.wwan1=interface
			uci set network.wwan1.proto='dhcp'
			uci commit network
			cp /etc/config/wireless-bak /etc/config/wireless
			uci set wireless.@wifi-iface[1].disabled=0
			uci set wireless.@wifi-iface[2].disabled=1
			uci commit wireless		
			wifi
		else
			echo "Usage:"
			echo "	7601_test.sh on/off		-----Enable/Disable two 7601 "
			echo "	7601_test.sh 45/46 on/off	------Enable/Disable one 7601"
			echo ""
		fi		
	elif [ $1 = "46" ]
	then
		if [ $2 == "on" ]
		then
			echo 1 > /sys/class/gpio/gpio46/value
			echo "7601-2 ON"
		elif [ $2 = "off" ]
		then
			echo 0 > /sys/class/gpio/gpio46/value
			echo "7601-2 OFF"
		elif [ $2 == "test" ]
		then
			uci set network.wwan=interface
			uci set network.wwan.proto='dhcp'
			uci set network.wwan1=interface
			uci set network.wwan1.proto='dhcp'
			uci commit network
			cp /etc/config/wireless-bak /etc/config/wireless
			uci set wireless.@wifi-iface[1].disabled=1
			uci set wireless.@wifi-iface[2].disabled=0
			uci commit wireless
			wifi
		else
			echo "Usage:"
			echo "	7601_test.sh on/off		-----Enable/Disable two 7601 "
			echo "	7601_test.sh 45/46 on/off	------Enable/Disable one 7601"
			echo ""
		fi	
	else
		echo "Usage:"
		echo "	7601_test.sh on/off		-----Enable/Disable two 7601 "
		echo "	7601_test.sh 45/46 on/off	------Enable/Disable one 7601"
		echo ""
	fi		
else
	echo "Usage:"
	echo "	7601_test.sh on/off		-----Enable/Disable two 7601 "
	echo "	7601_test.sh 45/46 on/off	------Enable/Disable one 7601"
	echo ""
fi

