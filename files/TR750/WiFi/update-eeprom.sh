#!/bin/ash

cd "$(dirname "$0")"

FACTORY_PART="/dev/mtd2"

BACKUP_FILE="EEPROM.bak"
DEFAULT_EEPROM="TR750-default-EEPROM.bin"
NEW_EEPROM="EEPROM-new.bin"


if [ -f "$BACKUP_FILE" ]; then
    echo "EEPROM has been updated"
    exit 1
fi


cp $DEFAULT_EEPROM $NEW_EEPROM

# 2.4G MAC
dd if=$FACTORY_PART of=$NEW_EEPROM bs=1 count=56 conv=notrunc

# 2.4G frequency offset
dd if=$FACTORY_PART of=$NEW_EEPROM skip=244 seek=244 bs=1 count=3 conv=notrunc

# 5G MAC
dd if=$FACTORY_PART of=$NEW_EEPROM skip=32772 seek=32772 bs=1 count=6 conv=notrunc

# 5G frequency offset
dd if=$FACTORY_PART of=$NEW_EEPROM skip=32842 seek=32842 bs=1 count=4 conv=notrunc

cat $FACTORY_PART > $BACKUP_FILE

mtd write $NEW_EEPROM $FACTORY_PART

echo "EEPROM update finished"
