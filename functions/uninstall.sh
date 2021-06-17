#!/bin/bash

format_usb() {
alert_info 'INFO' "Effacement des métadonnées du disque /dev/${disk} !"
read -p '---> Taper sur entrée pour valider (Ctrl+c pour quitter)'
echo

dd if=/dev/zero of=/dev/${disk} bs=1M count=100 conv=noerror,sync &
#too much speed for use status=progress
pid_dd="$!"
while (ps -q $pid_dd -o state --no-headers)
do
  echo "Effacement en cours (PID: $pid_dd) !" 
  kill -USR1 $pid_dd
  sleep 1
done

#Create new partition
alert_info 'INFO' "Création de la partition ${disk}1"
echo 'type=b' | sfdisk /dev/"${disk}" #&
# wait $!

#Format partition
alert_info 'INFO' "Formatage de la partition ${disk}1 en FAT32"
mkfs.fat -I -F 32 /dev/"${disk}"1 &
wait $!

#inform the operating system of partition table changes
partprobe

#Make USB label
alert_info 'INFO' "Création d'un nom de label pour la clé USB !"
label_usb="USB_${RANDOM}"
mlabel -i /dev/"${disk}"1 -s ::"$label_usb" > /dev/null && echo "USB renommée en $label_usb !"

echo
for i in {1..3}
do
  echo -en "-- Merci de patienter ${i}/3 secondes --\r"
  sleep 1
done
echo

sync

eject /dev/"${disk}" && echo -e "\nDisque USB $label_usb éjecté !"

alert_info 'INFO' "Vous pouvez retirer la clé USB en toute sécurité !"
}
