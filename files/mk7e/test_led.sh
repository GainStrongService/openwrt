#!/bin/sh

change_all_les_status() {
    echo "turning on all LED"
    echo $1 > /sys/class/leds/red_0/brightness
    echo $1 > /sys/class/leds/green_0/brightness
    echo $1 > /sys/class/leds/blue_0/brightness

    echo $1 > /sys/class/leds/red_1/brightness
    echo $1 > /sys/class/leds/green_1/brightness
    echo $1 > /sys/class/leds/blue_1/brightness

    echo $1 > /sys/class/leds/red_2/brightness
    echo $1 > /sys/class/leds/green_2/brightness
    echo $1 > /sys/class/leds/blue_2/brightness

    echo $1 > /sys/class/leds/red_3/brightness
    echo $1 > /sys/class/leds/green_3/brightness
    echo $1 > /sys/class/leds/blue_3/brightness
}


turn_on_then_off() {
    echo "LED 1 Red"
    echo 1 > /sys/class/leds/red_0/brightness
    sleep 2
    echo 0 > /sys/class/leds/red_0/brightness
    echo "LED 1 Green"
    echo 1 > /sys/class/leds/green_0/brightness
    sleep 2
    echo 0 > /sys/class/leds/green_0/brightness
    echo "LED 1 Blue"
    echo 1 > /sys/class/leds/blue_0/brightness
    sleep 2
    echo 0 > /sys/class/leds/blue_0/brightness

    echo "LED 2 Red"
    echo 1 > /sys/class/leds/red_1/brightness
    sleep 2
    echo 0 > /sys/class/leds/red_1/brightness
    echo "LED 2 Green"
    echo 1 > /sys/class/leds/green_1/brightness
    sleep 2
    echo 0 > /sys/class/leds/green_1/brightness
    echo "LED 2 Blue"
    echo 1 > /sys/class/leds/blue_1/brightness
    sleep 2
    echo 0 > /sys/class/leds/blue_1/brightness

    echo "LED 3 Red"
    echo 1 > /sys/class/leds/red_2/brightness
    sleep 2
    echo 0 > /sys/class/leds/red_2/brightness
    echo "LED 3 Green"
    echo 1 > /sys/class/leds/green_2/brightness
    sleep 2
    echo 0 > /sys/class/leds/green_2/brightness
    echo "LED 3 Blue"
    echo 1 > /sys/class/leds/blue_2/brightness
    sleep 2
    echo 0 > /sys/class/leds/blue_2/brightness

    echo "LED 4 Red"
    echo 1 > /sys/class/leds/red_3/brightness
    sleep 2
    echo 0 > /sys/class/leds/red_3/brightness
    echo "LED 4 Green"
    echo 1 > /sys/class/leds/green_3/brightness
    sleep 2
    echo 0 > /sys/class/leds/green_3/brightness
    echo "LED 4 Blue"
    echo 1 > /sys/class/leds/blue_3/brightness
    sleep 2
    echo 0 > /sys/class/leds/blue_3/brightness
}

OPERATION=$1

if [ "$OPERATION" == "" ]; then
    OPERATION="on"
fi

if [ $OPERATION == "on" ]
then
    change_all_les_status 1
fi

if [ $OPERATION == "off" ]
then
    change_all_les_status 0
fi

if [ $OPERATION == "onoff" ]
then
    change_all_les_status 0
    turn_on_then_off
    change_all_les_status 1
fi