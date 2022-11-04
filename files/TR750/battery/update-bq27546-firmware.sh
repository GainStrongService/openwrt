#!/bin/ash

rmmod bq27xxx_battery_i2c

bqtool --bqfs-flash --bqfs-file=/TR750/battery/0546_2_01-bq27546G1.bq.fs

modprobe bq27xxx_battery_i2c
