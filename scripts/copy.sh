#!/bin/bash
mount /mnt/yoghi-usb
rsync -progress --modify-window=1 --update --recursive --times --stats --human-readable build/* /mnt/yoghi-usb 
time umount /mnt/yoghi-usb 
mount /mnt/yoghi-usb
ls /mnt/yoghi-usb
umount /mnt/yoghi-usb