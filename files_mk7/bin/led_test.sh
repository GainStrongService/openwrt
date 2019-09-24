#!/bin/sh

echo 3 > /sys/class/gpio/export
echo 2 > /sys/class/gpio/export
echo 0 > /sys/class/gpio/export
echo out  > /sys/class/gpio/gpio3/direction
echo out  > /sys/class/gpio/gpio2/direction
echo out  > /sys/class/gpio/gpio0/direction

while [ 1 ]
do
	echo 1 > /sys/class/gpio/gpio0/value 
	echo 0 > /sys/class/gpio/gpio2/value 
	echo 0 > /sys/class/gpio/gpio3/value 
	sleep 1
	echo 0 > /sys/class/gpio/gpio0/value 
	echo 1 > /sys/class/gpio/gpio2/value 
	echo 0 > /sys/class/gpio/gpio3/value 
	sleep 1
	echo 0 > /sys/class/gpio/gpio0/value 
	echo 0 > /sys/class/gpio/gpio2/value 
	echo 1 > /sys/class/gpio/gpio3/value 	
	sleep 1
done

