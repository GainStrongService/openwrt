#!/bin/sh
GPIOBASE=`cat /sys/class/gpio/gpiochip*/base | head -n1`
GPIOmin=`expr $1 + $GPIOBASE`
GPIOmax=`expr $2 + $GPIOBASE`
 
cd /sys/class/gpio
for i in `seq $GPIOmin $GPIOmax`; do
echo $i > export; echo in >gpio$i/direction
done
nums=`seq $GPIOmin $GPIOmax`
while true; do
  for i in $nums; do
     echo read gpio$i 
     cat /sys/class/gpio/gpio$i/value
 done
  sleep 1
done