#!/bin/bash

select_user() {
tab_users=()

nb_users='0'

u_id=$(awk -F':' '{print $3}' /etc/passwd)

min=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)
max=$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)

for user in ${u_id}
do
  if [[ $user -ge $min && $user -le $max ]]
  then
    user_name=$(grep ":${user}:${user}:" /etc/passwd | awk -F':' '{print $1}')
    tab_users+=("$user_name")
    ((nb_users++))
  fi  
done

if [[ ${nb_users} -gt '1' ]]
then 
  PS3="Votre choix : "

  echo -e "\n -- INFO: Plusieurs utilisateurs détectés -- "
  select ITEM in "${tab_users[@]}" 'Quitter'
  do
    if [[ $ITEM == 'Quitter' ]]
    then
      echo "Fin du programme!"
      exit
    else
      final_user="$ITEM"
      break
    fi
  done
elif [[ ${nb_users} -eq '1' ]]
then
  final_user="$user_name"
else
  echo -e "\n Ce système ne contient pas d'utilisateurs autre que ROOT \n"
  exit 1
fi
}


ventoy_start_virtualbox() {
echo -e "\n Liste des ISO's "
echo "--------------------"
if [[ $(find ${v_dir} -type f -name "*.iso" | wc -l) -le "1" ]]
then
  alert_info 'INFO' "Il y a pas d'ISO's dans le dossier ventoy"
  exit 1
fi

find ${v_dir} -type f -name "*.iso" | cut -d'/' -f4

select_user
    
usermod -a -G vboxusers "${final_user}"
usermod -a -G disk "${final_user}"

# Se connecter avec les nouveaux groupes
newgrp - "${final_user}" vboxusers
newgrp - "${final_user}" disk

# Création du disk VMDK
su - "${final_user}" -c "VBoxManage internalcommands createrawvmdk -filename  /tmp/usb.vmdk -rawdisk /dev/${disk}"

chown "${final_user}":"${final_user}" /tmp/usb.vmdk

# Création de la configuration de la VM
vm_name='Ventoy_USB'

su - "${final_user}" -c "VBoxManage createvm --name ${vm_name} --ostype Linux_64 --register"
su - "${final_user}" -c "VBoxManage modifyvm ${vm_name} --ioapic on"
su - "${final_user}" -c "VBoxManage modifyvm ${vm_name} --memory 2048 --vram 256"
su - "${final_user}" -c "VBoxManage modifyvm ${vm_name} --nic1 nat"

# Configuration et attachement du disque VMDK
su - "${final_user}" -c "VBoxManage storagectl ${vm_name} --name "SATA Controller" --add sata --controller IntelAhci"
su - "${final_user}" -c "VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium /tmp/usb.vmdk"

# Démarrer la VM
su - "${final_user}" -c "VBoxManage startvm ${vm_name}"

alert_info 'INFO' "Vm en cours de fonctionnement"
read -r -p "Cliquer sur entrée pour valider !"
}
