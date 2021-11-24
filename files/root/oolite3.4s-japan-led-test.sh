#!/bin/bash

led_gpio_list=(16 14 19 18 11 20 41 17 44 15 43 39 21 42 40 46 45 1 3 5 0 2 4 37)

change_all_led_status() {
    [[ "$1" = 0 ]] && echo "turn on all LED" || echo "turn off all LED" 
    for led in "${led_gpio_list[@]}"
    do
        echo -n $1 > /sys/class/leds/led_gpio_$led/brightness
    done
}

turn_on_then_off() {
    for led in "${led_gpio_list[@]}"
    do
        echo "testing gpio $led"
        echo -n 0 > /sys/class/leds/led_gpio_$led/brightness
        sleep 0.2
        echo -n 1 > /sys/class/leds/led_gpio_$led/brightness
    done
}

led_loop_on_off() {
    while true
    do
        change_all_led_status 1
        sleep 1
        turn_on_then_off
        turn_on_then_off
        change_all_led_status 0
        sleep 2
    done
}

OPERATION=$1

if [ "$OPERATION" = "on" ]
then
     change_all_led_status 0
elif [ "$OPERATION" = "off" ]
then
    change_all_led_status 1
else
    led_loop_on_off
fi