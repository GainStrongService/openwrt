#!/bin/sh
# Modified from https://gist.github.com/huzhifeng/e3c222e6b780d82967db
echo GPIO Button Test
echo   Usage: $0 [gpio start] [gpio end]
echo Example: $0 0 1
echo leave gpio range blank to test all GPIOs.
echo 
for GPIOCHIP in /sys/class/gpio/gpiochip*/ ; do
    BASE=$(cat ${GPIOCHIP}base)
    SIZE=$(cat ${GPIOCHIP}ngpio)
    MAX=$(($BASE+$SIZE-1))
    gpio_end=${2:-$MAX}
    [ -z "$gpio" ] && gpio=${1:-$BASE}
    while [ $gpio -ge $BASE -a $gpio -le $MAX -a $gpio -le $gpio_end ] ; do
        # Save original value if needed
        if [ -d /sys/class/gpio/gpio${gpio} ]; then
            DIRECTION=$(cat /sys/class/gpio/gpio${gpio}/direction)
            UNEXPORT=0
        else
            echo $gpio > /sys/class/gpio/export
            UNEXPORT=1
            DIRECTION=""
        fi
        if [ -d /sys/class/gpio/gpio${gpio} ]; then
            echo in > /sys/class/gpio/gpio${gpio}/direction
            echo "[gpiochip${BASE}:${gpio}:in] = $(cat /sys/class/gpio/gpio${gpio}/value)"
 
            # Restore original value
            [ ! -z "$DIRECTION" ] && echo $DIRECTION > /sys/class/gpio/gpio${gpio}/direction
            [ "$UNEXPORT" -eq 1 ] && echo ${gpio} > /sys/class/gpio/unexport
        else
            echo "[gpiochip${BASE}:${gpio}] = Failed to export"
        fi
 
        gpio=$((gpio+1))
    done
done