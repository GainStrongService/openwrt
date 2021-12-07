#!/bin/sh
# Modified from https://gist.github.com/huzhifeng/e3c222e6b780d82967db
echo GPIO LED Test
echo   Usage: $0 [wait time] [gpio start] [gpio end]
echo Example: $0 3s 0 1
echo leave gpio range blank to test all GPIOs.
echo
wait=${1:-"3s"}
for GPIOCHIP in /sys/class/gpio/gpiochip*/ ; do
    BASE=$(cat ${GPIOCHIP}base)
    SIZE=$(cat ${GPIOCHIP}ngpio)
    MAX=$(($BASE+$SIZE-1))
    gpio_end=${3:-$MAX}
    [ -z "$gpio" ] && gpio=${2:-$BASE}
    while [ $gpio -ge $BASE -a $gpio -le $MAX -a $gpio -le $gpio_end ] ; do
        # Save original value if needed
        if [ -d /sys/class/gpio/gpio${gpio} ]; then
            DIRECTION=$(cat /sys/class/gpio/gpio${gpio}/direction)
            UNEXPORT=0
            VALUE=$(cat /sys/class/gpio/gpio$gpio/value)
        else
            echo $gpio > /sys/class/gpio/export
            UNEXPORT=1
            DIRECTION=""
            VALUE=""
        fi
        if [ -d /sys/class/gpio/gpio${gpio} ]; then
            echo out > /sys/class/gpio/gpio$gpio/direction
 
            echo "[gpiochip${BASE}:$gpio:out] = 0"
            echo 0 > /sys/class/gpio/gpio$gpio/value
            sleep $wait
 
            echo "[gpiochip${BASE}:$gpio:out] = 1"
            echo 1 > /sys/class/gpio/gpio$gpio/value
            sleep $wait
 
            # Restore original value
            [ ! -z "$DIRECTION" ] && echo $DIRECTION > /sys/class/gpio/gpio${gpio}/direction
            [ ! -z "$VALUE" ] && echo $VALUE > /sys/class/gpio/gpio${gpio}/value
            [ "$UNEXPORT" -eq 1 ] && echo ${gpio} > /sys/class/gpio/unexport
        else
            echo "[gpiochip${BASE}:${gpio}] = Failed to export"
        fi
 
        gpio=$((gpio+1))
    done
done