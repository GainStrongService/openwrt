#!/bin/sh

if [ ! -d "/sys/class/gpio/gpio5" ]
then
	echo 5 > /sys/class/gpio/export
	echo out  > /sys/class/gpio/gpio5/direction
	echo 1 > /sys/class/gpio/gpio5/value
fi

if [ $# -eq 1 ]
then
	if [ $1 == "on" ]
	then
		echo 0 > /sys/class/gpio/gpio5/value
		echo "USB ON"
	elif [ $1 = "off" ]
	then
		echo 1 > /sys/class/gpio/gpio5/value
		echo "USB OFF"
	else
		echo "Usage:"
		echo "	usb_test.sh on/off"
		echo ""
	fi	
else
	echo "Usage:"
	echo "	usb_test.sh on/off"
	echo ""
fi

