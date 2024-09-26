#!/bin/bash
mount /mnt/yoghi-usb
rsync -progress --modify-window=1 --update --recursive --times --stats --human-readable build/* /mnt/yoghi-usb
time umount /mnt/yoghi-usb
mount /mnt/yoghi-usb
ls /mnt/yoghi-usb
cp CDC-BitPrepared_USB2023.md5 /mnt/yoghi-usb
cd /mnt/yoghi-usb
md5sum -c CDC-BitPrepared_USB2023.md5
rm CDC-BitPrepared_USB2023.md5
cd
umount /mnt/yoghi-usb
