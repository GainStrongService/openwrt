#!/bin/ash

LOW_POWER_LIMIT=4

while true
do
    capacity=$(cat /sys/class/power_supply/bq27546-0/capacity)
    status=$(cat /sys/class/power_supply/bq27546-0/status)

    #echo $capacity | tee /dev/console
    #echo $status | tee /dev/console

    if [ $status = "Discharging" -a $capacity -le $LOW_POWER_LIMIT ]; then
        uptime=$(uptime | awk '{print $3}')
        if [ $uptime -le 1 ]; then
            echo "Low battery, will power off immediately" | tee /dev/console
            poweroff
            sleep 2
        fi

        echo "Low battery, please plug in the charger or the system will shut down after 30 seconds" | tee /dev/console
        sleep 30
        status=$(cat /sys/class/power_supply/bq27546-0/status)
        echo $status | tee /dev/console

        if [ $status = "Discharging" ]; then
            poweroff
        fi
    fi

    sleep 30
done
