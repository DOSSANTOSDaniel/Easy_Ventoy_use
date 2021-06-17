#!/bin/bash

menu_images() {
echo -e "\n -- Menu fichiers -- \n"
select ITEM in "${files[@]}" 'Retour' 'Quitter'
do
  if [[ "${ITEM}" == "Quitter" ]]
  then
    echo "Fin du script !"
    exit 1
  elif [[ "${ITEM}" == "Retour" ]]
  then
    retour_images
    break
  else
    total="${total}/${ITEM}"
    ((count++))
    break
  fi
done
}

retour_images() {
if [[ ${count} -gt 0 ]]
then
  total="$(dirname "${total}")"
  ((count--))
fi
}

custom_title_and_background() {
v_dir="/tmp/bootusb"

IFS=$'\n'
PS3="Votre choix : "
total="/home/$(logname)"
mapfile -t files < <(ls ${total})
count=0
select_file=""

while :
do
  mapfile -t files < <(ls ${total})
  menu_images
  if [[ -f "${total}" ]]
  then
    select_file="${total}"
    dir_img="$select_file"
    name_img="$(basename $dir_img)"

    # test si png
    image_ext=$(file $dir_img | cut -d' ' -f2)

    # test la résolution =~ 1920x1080
    image_size=$(file $dir_img | cut -d' ' -f5-7)
  
    if [[ $image_ext == "PNG" && $image_size == "1920 x 1080," ]]
    then
      echo "Image validée !"
      select_file="${total}"
      break
    else
      echo -e "\nL'image n'est pas adaptée merci de selectionner une image valide !"
      echo "Format     : PNG"
      echo -e "Résolution : 1920 x 1080\n"
      read -r -p "Appuyer sur entée pour aller au menu"
      retour_images
    fi
  fi
done

mkdir "$v_dir"
mount /dev/"${disk}"2 $v_dir

# Titre à mettre
echo -e "\nChoix du titre pour le menu ventoy (laisser vide pour le choix par defaut)\n"
read -r -p "Votre choix : " title

sed -i "s/title-text: ".*"/title-text: \"${title}\"/" ${v_dir}/grub/themes/ventoy/theme.txt

# Copie sur la clé usb
cp $dir_img "${v_dir}"/grub/themes/ventoy/

# renomer l'image
rm -rf "${v_dir}"/grub/themes/ventoy/background.png

mv "${v_dir}"/grub/themes/ventoy/"${name_img}" "${v_dir}"/grub/themes/ventoy/background.png

sleep 1

echo "Démontage des partitions montées sur le disque USB /dev/${disk} !"
umount /dev/"${disk}"* > /dev/null 2>&1 & 
wait $!

eject /dev/"${disk}" && echo -e "\nDisque USB éjecté !"

rm -rf /tmp/bootusb

echo "Vous pouvez retirer la clé USB en toute sécurité !"
}
