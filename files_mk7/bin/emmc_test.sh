#!/bin/sh

if [ $# -eq 2 ]&&[ $2 = "mk" ]
then
	mkfs.vfat -F 32 /dev/mmcblk0
	if [ $1 = "mount" ]
	then
		mkdir /mnt/emmc
		mount /dev/mmcblk0 /mnt/emmc
		#echo "mount success"
		df -h
		exit
	else
		echo "Usage:"
		echo "	emmc_test.sh mount/umount"
		echo ""
		exit
	fi
fi
		
if [ $# -eq 1 ]
then
	if [ $1 = "mount" ]
	then
		mkdir /mnt/emmc
		mount /dev/mmcblk0 /mnt/emmc
		#echo "mount success"
		df -h
	elif [ $1 = "umount" ]
	then
		umount /mnt/emmc
		rm -rf /mnt/emmc
		echo "umount success"
		df -h
	else
		echo "Usage:"
		echo "	emmc_test.sh mount/umount"
		echo ""
	fi
else
		echo "Usage:"
		echo "	emmc_test.sh mount/umount"
		echo ""
fi

