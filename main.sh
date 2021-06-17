#!/bin/bash

#************************************************#
# Nom:     main.sh                      
# Auteur:  <dossantosjdf@gmail.com>              
# Date:    06/01/2021                            
# Version: 1.1 17/06/2021                                   
#                                                
# Rôle:                                          
# Ce script va permettre de faciliter            
# l'utilisation de Ventoy.
#
# Détail des fonctionnalités :
# 1. Installation automatique de Ventoy sur une clé.
# 2. Mise à jour de Ventoy.
# 3. Réinstallation de Ventoy.
# 4. Formatage de la clé USB.
# 5. Customisation du menu de démarrage de Ventoy.
#
# Usage:   ./main.sh -[h|v]
# -h : Aide.
# -v : Affiche la version.
#
# Limites: <limites d'utilisation>               
# Contraintes:
# Licence:
#************************************************#

### Inclusions ###
source functions/custom_menu.sh
source functions/update.sh
source functions/install_usb.sh
source functions/uninstall.sh
source functions/reinstall.sh
source functions/install_pc.sh
# source functions/persist_iso.sh (à venir)
# source functions/run_on_virtualbox.sh (à venir)

### Fonctions ###
usage() {

  cat << EOF
  ___ Script : $(basename "${0}") ___
  
  $(basename "${0}") -[h|v]
  
  Le script doit être lancé en tant que root.
  C'est un script interactif.
  
  Donnée à saisir pendant l’exécution du script :
  *. Nom de la partition sur la clé USB (sda,sdb..).
  *. Nom de la distribution a (installer, supprimer...).
  
  Rôle:                                          
  Ce script va permettre de faciliter            
  l'utilisation de Ventoy.

  Détail des fonctionnalités :
  1. Installation automatique de Ventoy sur une clé.
  2. Mise à jour de Ventoy.
  3. Réinstallation de Ventoy.
  4. Formatage de la clé USB.
  5. Customisation du menu de démarrage de Ventoy.
  
  Usage: ./$(basename "${0}") -[h|v]
  -h : Aide.
  -v : Affiche la version.
  
EOF
}

version() {
  local ver='1.1'
  local dat='17/06/2021'
  
  cat << EOF
  
  ___ Script : $(basename "${0}") ___
  
  Version : ${ver}
  Date : ${dat}
  
  Version de Ventoy : $version
EOF
}

alert_info()
{
  local msg1="${1}" # $1 : ERREUR, INFO
  local msg2="${2}" # $2 : Informations.

  #Colors
  local red="\033[0;31m"
  local green="\033[0;32m"
  local nc="\033[0m" # Stop Color

  if [[ ${1} == 'ERREUR' ]]
  then
    echo -e "\n${red}>>> $msg1 : $msg2 ...${nc}\n"
  elif [[ ${1} == 'INFO' ]]
  then
    echo -e "\n${green}>>> $msg1 : $msg2 ...${nc}\n"
  else
    echo -e "\n>>> $msg2 ...\n"
  fi
}

test_user()
{
  if [[ $UID -ne 0 ]]
  then
    alert_info 'INFO' 'Le script doit être exécuté en tant que ROOT !'
    usage
    exit 1
  fi
}

mount_usb() {
# mount the two partitions
usb_dir='/tmp/diskusb'
boot_dir='/tmp/diskboot'

if [[ ! -d "/tmp/diskusb" ]]
then
  mkdir "$usb_dir"
  sleep 2
elif [[ ! -d "/tmp/diskboot" ]]
then
  mkdir "$boot_dir"
  sleep 2
fi

mount /dev/"${disk}"1 "$usb_dir"
sleep 2
mount /dev/"${disk}"2 "$boot_dir"
sleep 2
}

umount_usb() {
if ! [[ $disk = 'false' ]]
then 
  if (mount | grep ${disk} > /dev/null)
  then
    alert_info 'INFO' "Démontage des partitions montées sur le disque USB /dev/${disk} !"
  
    umount -l /dev/${disk}* > /dev/null 2>&1 & 
    wait $!
  elif ! (mount | grep ${disk} > /dev/null)
  then
    alert_info 'INFO' "Démontage OK !"
  else
    alert_info 'ERROR' "Erreur du démontage des partitions sur le disque USB /dev/${disk} !"
    exit 1
  fi
fi
}

end_script() {
  alert_info 'INFO' 'Fin du script'
}

### Main ###
# Variables
version="1.0.45"
disk='false'

trap "{ umount_usb ; end_script; }" SIGINT SIGTERM ERR EXIT

# Bannière
cat << "EOF"
__     _______                __ _
\ \   / /_   _|__ ___  _ __  / _(_) __ _
 \ \ / /  | |/ __/ _ \| '_ \| |_| |/ _` |
  \ V /   | | (_| (_) | | | |  _| | (_| |
   \_/    |_|\___\___/|_| |_|_| |_|\__, |
                                   |___/

EOF

# Test de l'utilisateur
test_user

# GetOps
while getopts "hv" arguments
do
  case "${arguments}" in
    h)
      clear
      usage
      exit 1
      ;;
    v)
      clear
      version
      exit 1
      ;;
    *)
      alert_info 'ERREUR' 'Argument non valide !'
      usage
      exit 1
      ;;
  esac
done

# Dépendances
mount.exfat-fuse -V >> /dev/null || (apt-get update && apt-get install -y exfat-fuse)

# Menu disk
valide_disk="false"

while [ $valide_disk == "false" ]
do
  IFS=$'\n'
  PS3="Votre choix : "
  
  echo -e "\n Merci de brancher la clé USB \n"
  read -r -p "Taper sur entrée pour valider"
  clear
  
  mapfile -t disks < <(lsblk -ldn -I 8 -o NAME,SIZE,MODEL)
  
  echo -e "\n-- Menu disques --\n"
  select ITEM in "${disks[@]}" 'Relancer' 'Quitter'
  do
    if [[ "${ITEM}" == "Quitter" ]]
    then
      exit 1
    elif [[ "${ITEM}" == "Relancer" ]]
    then
      clear
      break
    else
      disk=$(echo $ITEM | cut -d' ' -f1)
      
      # Regex
      regex="^[s][d][a-z]$"

      if [[ ! ${disk} =~ ${regex} || -z ${disk} ]]
      then
        alert_info 'ERREUR' 'Saisie non valide !'
        break
      elif (grep ${disk} /etc/fstab > /dev/null)
      then
        alert_info 'ERREUR' "Attention le disque ${disk} est utilisé par le système !"
        exit 1
      else
        valide_disk="true"
      fi
      break
    fi
  done
done

# test if ventoy is installed usb or pc
usb_installed="false"
pc_installed="false"

# Test if ventoy was installed in usb
part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/"${disk}"1 2> /dev/null)
part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/"${disk}"2 2> /dev/null)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  usb_installed="true"
fi

# check if installed pc
if [[ $(ls /opt/ventoy-*) ]]
then
  pc_installed="true"
fi

umount_usb

clear

# Menu
echo "Menu de configurations"
echo "----------------------"
PS3='Votre choix: '
options=('Install Ventoy' 'Format USB' 'Reinstall Ventoy' 'Update Ventoy' 'Custom Ventoy' 'ISO Persistence' 'Start in VirtualBox' 'Quit')
select opt in "${options[@]}"
do
  case $opt in
    'Install Ventoy')
      if [[ $pc_installed == "false" && $usb_installed == "false" ]]
      then
        alert_info 'INFO' 'Installation de Ventoy sur le PC !'
        install_pc
        alert_info 'INFO' 'Installation de Ventoy sur la clé USB !'
        install_usb
      elif [[ $pc_installed == "false" ]]
      then
        alert_info 'INFO' 'Installation de Ventoy sur le PC !'      
        install_pc
      elif [[ $usb_installed == "false" ]]
      then
        alert_info 'INFO' 'Installation de Ventoy sur la clé USB !'
        install_usb
      else
        alert_info 'INFO' 'Ventoy est déjà installé sur le PC et la clé USB !'
      fi
      break
      ;;
    'Format USB')
      alert_info 'INFO' "Suppression de Ventoy sur la clé USB en cours"
      format_usb
      break
      ;;
    'Reinstall Ventoy')
      if [[ $pc_installed == "true" && $usb_installed == "true" ]]
      then
        alert_info 'INFO' "Réinstallation de Ventoy sur la clé USB en cours"
        ventoy_reinstall
      else
        alert_info 'INFO' "Ventoy n'est pas installé (USB ou sur PC)"
        sleep 3
      fi
      break
      ;;
    'Update Ventoy')
      alert_info 'INFO' "Mise à jour de Ventoy sur la clé USB en cours"
      ventoy_update
      break
      ;;
    'ISO Persistence')
      #ventoy_persist_iso
      echo -e "\n La fonction ISO Persistence n'est pas encore implémentée ! \n"
      break      
      ;;
    'Start in VirtualBox')
      #ventoy_start_virtualbox
      echo -e "\n La fonction Start in VirtualBox n'est pas encore implémentée ! \n"
      break      
      ;;
    'Custom Ventoy')
      custom_title_and_background
      break      
      ;;
    'Quit')
      exit 1
      ;;
    *)
      echo "Option invalide : ${REPLY}"
      ;;
  esac
done
