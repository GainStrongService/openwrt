#!/bin/sh
GPIOBASE=`cat /sys/class/gpio/gpiochip*/base | head -n1`
GPIOmin=`expr $1 + $GPIOBASE`
GPIOmax=`expr $2 + $GPIOBASE`
 
cd /sys/class/gpio
for i in `seq $GPIOmin $GPIOmax`; do
     echo "[GPIO$i] Trying value $3"
     echo $i > export; echo out >gpio$i/direction
     echo $3 > gpio$i/value
     echo $i > unexport
done