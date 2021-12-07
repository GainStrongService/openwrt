#!/bin/sh
 
show_usage()
{
    printf "\ngpio.sh <gpio pin number> [in|out [<value>]]\n"
}
 
if [ \( $# -eq 0 \) -o \( $# -gt 3 \) ] ; then
    show_usage
    printf "\n\nERROR: incorrect number of parameters\n"
    exit 255
fi
 
GPIOBASE=`cat /sys/class/gpio/gpiochip*/base | head -n1`
GPIO=`expr $1 + $GPIOBASE`
 
#doesn't hurt to export a gpio more than once
(echo $GPIO > /sys/class/gpio/export) >& /dev/null
 
if [  $# -eq 1 ] ; then
   cat /sys/class/gpio/gpio$GPIO/value
   exit 0
fi
 
if [ \( "$2" != "in" \) -a  \( "$2" != "out" \) ] ; then
    show_usage
    printf "\n\nERROR: second parameter must be 'in' or 'out'\n"
    exit 255
fi
 
echo $2 > /sys/class/gpio/gpio$GPIO/direction
 
if [  $# -eq 2 ] ; then
   cat /sys/class/gpio/gpio$GPIO/value
   exit 0
fi
 
 
VAL=$3
 
if [ $VAL -ne 0 ] ; then
    VAL=1
fi
 
echo $VAL > /sys/class/gpio/gpio$GPIO/value  