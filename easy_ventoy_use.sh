#!/bin/bash

#************************************************#
# Nom:     script_ventoy.sh                      
# Auteur:  <dossantosjdf@gmail.com>              
# Date:    06/01/2021                            
# Version: 0.1                                   
#                                                
# Rôle:                                          
# Ce script va permettre de faciliter            
# l'utilisation de Ventoy.
#
# Détail des fonctionnalités :
# 1. Installation automatique de Ventoy sur une clé.
# 2. Mise à jour de Ventoy.
# 3. Ajout d'ISOs.
# 4. Supression d'ISOs.
# 5. Mise en place de la persistance.
# 6. Lancer Ventoy sur VirtualBox ou KVM.
#
# Usage:   ./script_ventoy.sh -[h|v]
# -h : Aide.
# -v : Affiche la version.
#
# Limites: <limites d'utilisation>               
# Contraintes:
# Licence:
#************************************************#

# Ne permet pas de variables inutilisées.
set -u

### Inclusions ###

### Fonctions ###
usage() {

  cat << EOF
  ___ Script : $(basename ${0}) ___
  
  Parametres passés : ${@}
  
  $(basename ${0}) -[h|v]
  
  Le script doit être lancé en tant que root.
  C'est un script interactif.
  
  Donnée à saisir pendant l’exécution du script :
  *. Nom de la partition sur la clé USB (sda,sdb..).
  *. Nom de la distribution a (installer, supprimer...) ou son chemin.
  *. Taille en GO pour la persistance de chaque distribution.
  
  Rôle:                                          
  Ce script va permettre de faciliter            
  l'utilisation de Ventoy.

  Détail des fonctionnalités :
  1. Installation automatique de Ventoy sur une clé.
  2. Mise à jour de Ventoy.
  3. Ajout d'ISOs.
  4. Supression d'ISOs.
  5. Mise en place de la persistance.
  6. Lancer Ventoy sur VirtualBox ou KVM.

  Usage: ./$(basename ${0}) -[h|v]
  -h : Aide.
  -v : Affiche la version.
  
EOF

exit 0
}

version() {

  local ver='0.1'
  local dat='06/01/21'
  cat << EOF
  
  ___ Script : $(basename ${0}) ___
  
  Version : ${ver}
  Date : ${dat}
  
EOF

exit 0
}

# $1 $2
alert_info() {
local msg1="${1}"
local msg2="${2}"
# $1 : ERREUR, INFO.
# $2 : Informations complémentaires.
echo -e "\n !!! ${msg1} : ${msg2} !!! \n"
}

#clean_exit() {
# Nettoyage 
#}

test_user() {
if [[ ${LOGNAME} != "root" ]]
then
  echo "Utilisateur : ${LOGNAME}"
  alert_info 'INFO' 'Le script doit être exécuté en tant que root' 
  exit 1
fi
}

dep_install() {
tab_app=()
case "$OSTYPE" in
  linux*)
    if [[ -f /etc/os-release || -f /etc/redhat-release || -f /etc/debian_version ]]
    then
      if [[ $(dpkg -s "apt" 2> /dev/null) || $(dpkg -s "apt-get" 2> /dev/null) ]]
      then
        pkg_os='apt-get'
        
        tab_app[0]='exfat-fuse'
        tab_app[1]=''
        tab_app[2]=''        
      elif [[ $(rpm -qi "dnf" 2> /dev/null) ]]
      then
        pkg_os='dnf'
        
        tab_app[0]='http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm'
        tab_app[1]='exfat-utils'
        tab_app[2]='fuse-exfat'
        
      elif [[ $(rpm -qi "yum" 2> /dev/null) ]]
      then
        pkg_os='yum'
        
        tab_app[0]='http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm'
        tab_app[1]='exfat-utils'
        tab_app[2]='fuse-exfat'      
        
      else
        alert_info 'INFO' 'Gestionnaire de paquets non prit en charge'
        exit 1
      fi
    fi ;;
  *) alert_info 'INFO' "OS non prit en charge : $OSTYPE" ;;
esac
}

if_installed_pc() {
  # verifie si installé
if [[ $(ls /opt/ventoy-${version}/ > /dev/null 2>&1) ]]
then
  alert_info 'INFO' "Ventoy est déjà installé sur l'ordinateur"
elif [[ $(ls /opt/ventoy-*/ > /dev/null 2>&1) ]]
then
  alert_info 'INFO' "Ventoy est déjà installé sur l'ordinateur mais il a une version différente"
  read -p "Voulez vous réinstaller Ventoy sur l'ordinateur [o]oui [n]non : " ch
  if [[ ${ch} == "o" || ${ch} == "O" ]]
  then
    # Téléchargement
    wget -c -O /opt/ventoy.tar.gz --progress='bar' https://github.com/ventoy/Ventoy/releases/download/v${version}/ventoy-${version}-linux.tar.gz

    if ! [[ -f /opt/ventoy.tar.gz ]]
    then
      alert_info 'ERREUR' "Erreur de téléchargement"
      exit 1
    fi
    
    # Décompression 
    if [[ $(tar -xvf /opt/ventoy.tar.gz -C /opt) ]]
    then
      rm -rf /opt/ventoy.tar.gz
      # un dossier boot
      # un dossier tool
      # un dossier ventoy
      # un dossier plugin
      # un fichier CreatePersistentImg.sh
      # un fichier Ventoy2Disk.sh
    else
      alert_info 'ERREUR' "Erreur de décompression"
      exit 1
    fi
  fi
fi
}

if_installed_usb() {
# Vérifie si Ventoy est installé sur clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  alert_info 'INFO' "Ventoy est déjà présent sur la clé USB"
  alert_info 'INFO' "Merci de choisir (Update Ventoy ou Reinstall Ventoy)" 
else
  echo -e "\n Installation de Ventoy sur la clé USB en cours \n"

# -i : Installation, mais si la clé contient déjà Ventoy alors erreur
# -s : Active la compatibilité de secure boot
# -g : Utilisation de partitions en GPT
  bash /opt/ventoy-${version}/Ventoy2Disk.sh -i -s -g /dev/${disk}

  alert_info 'INFO' "Installation de Ventoy sur /dev/${disk} terminée"
fi
}

ventoy_update() {
# Test si Ventoy est déjà installé sur le PC
if_installed_pc

# Détecte si Ventoy est déjà installé sur la clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  alert_info 'INFO' "Mise à jour de la clé USB en cours"
# -u : Mise à jour 
  bash /opt/ventoy-${version}/Ventoy2Disk.sh -u /dev/${disk}
else
  alert_info 'INFO' "Ventoy n'est pas installé sur la clé USB"
fi
}

ventoy_reinstall() {
# Test si Ventoy est déjà installé sur le PC
if_installed_pc

# Détecte si Ventoy est déjà installé sur la clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  alert_info 'INFO' "Réinstallation de la clé USB en cours"
  # -I : Force l'installation de Ventoy même si Ventoy est déjà installé sur la clé USB
  bash /opt/ventoy-${version}/Ventoy2Disk.sh -I -s -g /dev/${disk}
else
  alert_info 'INFO' "Ventoy n'est pas installé sur la clé USB"
fi
}

ventoy_remove() {
# Test si Ventoy est déjà installé sur le PC
if_installed_pc

# Détecte si Ventoy est déjà installé sur la clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  alert_info 'INFO' "Suppression de Ventoy de la clé USB en cours"
  echo -e "g\nn\n\n\n\nw" | fdisk /dev/${disk}
  mkfs.vfat -F 32 -n 'USB_KEY_0' /dev/${disk}1
else
  alert_info 'INFO' "Ventoy n'est pas installé sur la clé USB"
fi
}

ventoy_add_iso() {

echo -e "\n Quel OS voulez vous ? \n"

# Les distributions
url_Ubuntu=('ubuntu' 'https://releases.ubuntu.com/20.04.1/ubuntu-20.04.1-desktop-amd64.iso')
url_Debian=('debian' 'https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-10.7.0-amd64-xfce.iso')
url_MXLinux=('mxlinux' 'https://sourceforge.net/projects/mx-linux/files/Final/MX-19.3_x64.iso')
url_LinuxMint=('mint' 'http://ftp.crifo.org/mint-cd/stable/20.1/linuxmint-20.1-cinnamon-64bit.iso')
url_Kali=('kali' 'https://cdimage.kali.org/kali-2020.4/kali-linux-2020.4-live-amd64.iso')
url_ElementaryOS=('elementaryos' 'https://ams3.dl.elementary.io/download/MTYxMDEyNjkyOA==/elementaryos-5.1-stable.20200814.iso')
url_Fedora=('fedora' 'https://download.fedoraproject.org/pub/fedora/linux/releases/33/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-33-1.2.iso')
url_PopOS=('popos' 'https://pop-iso.sfo2.cdn.digitaloceanspaces.com/20.04/amd64/intel/18/pop-os_20.04_amd64_intel_18.iso')

# Montage
v_dir='/tmp/diskusb'
mkdir ${v_dir}
mount /dev/${disk}1 ${v_dir}

PS3='Votre choix: '
opt_os=('Ubuntu' 'Debian' 'MXLinux' 'LinuxMint' 'Kali' 'ElementaryOS' 'Fedora' 'PopOS' 'Other ISO' 'Quit')
select opt in "${opt_os[@]}"
do
  case $opt in
  'Ubuntu')
    if [[ $(ls ${v_dir}/${url_Ubuntu[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi
    wget -c -O ${v_dir}/${url_Ubuntu[0]}.iso --progress='bar' ${url_Ubuntu[1]}
  ;;
  'Debian')
    if [[ $(ls ${v_dir}/${url_Debian[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_Debian[0]}.iso --progress='bar' ${url_Debian[1]}
  ;;
  'MXLinux')
    if [[ $(ls ${v_dir}/${url_MXLinux[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_MXLinux[0]}.iso --progress='bar' ${url_MXLinux[1]}
  ;;
  'LinuxMint')
    if [[ $(ls ${v_dir}/${url_LinuxMint[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_LinuxMint[0]}.iso --progress='bar' ${url_LinuxMint[1]}
  ;;
  'Kali')
    if [[ $(ls ${v_dir}/${url_Kali[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_Kali[0]}.iso --progress='bar' ${url_Kali[1]}
  ;;
  'ElementaryOS')
    if [[ $(ls ${v_dir}/${url_ElementaryOS[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_ElementaryOS[0]}.iso --progress='bar' ${url_ElementaryOS[1]}
  ;;
  'Fedora')
    if [[ $(ls ${v_dir}/${url_Fedora[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_Fedora[0]}.iso --progress='bar' ${url_Fedora[1]}
  ;;
  'PopOS')
    if [[ $(ls ${v_dir}/${url_PopOS[0]}.iso) ]]
    then
      alert_info 'INFO' "L'ISO existe déjà"
      continue
    fi  
    wget -c -O ${v_dir}/${url_PopOS[0]}.iso --progress='bar' ${url_PopOS[1]}
  ;;
  'Other ISO')
    read -p "Chemin de l'ISO : " isos
    # ${isos}
    # A faire !!!
  ;;
  'Quit')
    exit 1
  ;;
  *)
    echo "Erreur de saisie"
    break
  ;;
  esac
done
}

ventoy_remove_iso() {
# Détecte si Ventoy est déjà installé sur la clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  # Montage
  v_dir='/tmp/diskusb'
  mkdir ${v_dir}
  mount /dev/${disk}1 ${v_dir}
  echo -e "\n Liste des ISO's "
  echo "--------------------"
  ls -l ${v_dir} | awk '{print $9}'
  read -p "Nom de l'ISO : " iso_rm
  if [[ $(rm -rf ${v_dir}/${iso_rm}) ]]
  then
    alert_info 'INFO' "Suppression de ${v_dir}/${iso_rm} réussie"
  fi  
else
  alert_info 'INFO' "Ventoy n'est pas installé sur la clé USB"
fi
}

ventoy_persist_iso() {
# installation de jq
apt-get install -qy jq

# Détecte si Ventoy est déjà installé sur la clé USB
local part_1=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}1)
local part_2=$(lsblk -fnl -o 'LABEL' -x 'LABEL' /dev/${disk}2)

if [[ ! ${part_1} == 'Ventoy' && ${part_2} == 'VTOYEFI' ]]
then
  alert_info 'INFO' "Ventoy n'est pas installé sur la clé USB"
  exit 1
fi
# Montage
v_dir='/tmp/diskusb'
mkdir ${v_dir}
mount /dev/${disk}1 ${v_dir}
  
# Persistence
mkdir ${v_dir}/ventoy
  
echo -e "\n Liste des ISO's "
echo "--------------------"
if [[ $(ls -l ${v_dir} | wc -l) -le "1" ]]
then
  alert_info 'INFO' "Il y a pas d'ISO's dans le dossier ventoy"
  exit 1
fi
ls -l ${v_dir} | awk '{print $9}'
read -p "Nom de l'ISO : " iso_pers
read -p "Taille de la persistence : " pers
  
if [[ ! ${pers} =~ [[:digit:]] ]]
then
  alert_info 'ERREUR' 'Erreur de saisie'
  exit 1
fi
  
bash /opt/ventoy-${version}/CreatePersistentImg.sh -s ${pers}
mv persistence.dat ${v_dir}/${iso_pers}.dat
  
### Traitement JSON  
if [[ ! -f ${v_dir}/ventoy/ventoy.json ]]
then
# création du fichier json
echo '
   {
     "persistence": [
     ]
   }
' > ${v_dir}/ventoy/ventoy.json
fi

obj="vide"
count_obj="0"
json_file="${v_dir}/ventoy/ventoy.json"
until [[ ${obj} == "null" ]]
do
  obj=$(jq ".persistence[${count_obj}]" ${json_file})
  (( count_obj++ ))
done

(( count_obj-- ))

# Ajouter des éléments
img_iso="/${iso_pers}.iso"
img_per="/${iso_pers}.dat"

jq_code=".persistence[${count_obj}] += { "\"image\"": "\"${img_iso}"\", "\"backend\"": "\"${img_per}\"" }"

jq "${jq_code}" ${json_file} > ${json_file}.tmp && mv ${json_file}.tmp ${json_file}
}

ventoy_start_virtualbox() {
echo -e "\n Liste des ISO's "
echo "--------------------"
if [[ $(ls -l ${v_dir} | wc -l) -le "1" ]]
then
  alert_info 'INFO' "Il y a pas d'ISO's dans le dossier ventoy"
  exit 1
fi
ls -l ${v_dir} | awk '{print $9}'

# Trouve le nom de l'utilisateur non root
min=$(grep ^UID_MIN /etc/login.defs | awk '{print $2}')
max=$(grep ^UID_MAX /etc/login.defs | awk '{print $2}')

user_id=$(cat /etc/passwd | awk -F':' '{print $3}')
nb_users='0'
for id in ${user_id}
do
  if [[ ${id} -ge ${min} && ${id} -le ${max} ]]
  then
    nom_user=$(cat /etc/passwd | grep ":${id}:${id}:" | awk -F':' '{print $1}')
    chown ${nom_user}:${nom_user} /tmp/usb.vmdk
    
    usermod -a -G vboxusers ${nom_user}
    usermod -a -G disk ${nom_user}
    
    echo "Utilisateur : ${nom_user}"
    (( nb_users++ ))
  fi  
done

if [[ ${nb_users} -gt '1' ]]
then
  alert_info 'INFO' "Plusieurs utilisateurs détectés"
  read -p "Choisir un utilisateur : " nom_user
fi

# Se connecter avec les nouveaux groupes
newgrp - ${nom_user} vboxusers
newgrp - ${nom_user} disk

# Création du disk VMDK
su - ${nom_user} -c "VBoxManage internalcommands createrawvmdk -filename  /tmp/usb.vmdk -rawdisk /dev/${disk}"

# Création de la configuration de la VM
vm_name='Ventoy_USB'

su - ${nom_user} -c "VBoxManage createvm --name ${vm_name} --ostype Linux_64 --register"
su - ${nom_user} -c "VBoxManage modifyvm ${vm_name} --ioapic on"
su - ${nom_user} -c "VBoxManage modifyvm ${vm_name} --memory 2048 --vram 256"
su - ${nom_user} -c "VBoxManage modifyvm ${vm_name} --nic1 nat"

# Configuration et attachement du disque VMDK
su - ${nom_user} -c "VBoxManage storagectl ${vm_name} --name "SATA Controller" --add sata --controller IntelAhci"
su - ${nom_user} -c "VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium /tmp/usb.vmdk"

# Démarrer la VM
su - ${nom_user} -c "VBoxManage startvm ${vm_name}"

alert_info 'INFO' "Vm en cours de fonctionnement"
read -p "Cliquer sur entrée pour valider !"

}

### Main ###
# set +e <----> set -e : quitte à la moindre erreur.

# Variables
version='1.0.31'

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

# Dépendances
dep_install

readonly os_sys="${pkg_os}"

for app in ${tab_app[@]}
do
  if [[ -n ${app} ]]
  then
    case $os_sys in
      'apt' | 'apt-get' )
	 if [[ ! $(dpkg -s ${app} 2> /dev/null) && $(command -v ${app} 2> /dev/null) ]]
         then
           echo -e "\n Installation de ${app} en cours \n"
           apt-get update -q
	   if [[ $(apt-get install -qy ${app}) ]]
           then
             alert_info 'INFO' "Installation de ${app} réussie"
           else
             alert_info 'ERREUR' "Installation de ${app} Impossible!"
             exit 1
           fi
         fi ;;
      'dnf' )
         if [[ ! $(rpm -qi ${app} 2> /dev/null) && $(command -v ${app} 2> /dev/null) ]]
         then
           echo -e "\n Installation de ${app} en cours \n"
           dnf check-update > /dev/null
	   if [[ $(dnf install -qy ${app}) ]]
           then
             alert_info 'INFO' "Installation de ${app} réussie"
           else
             alert_info 'ERREUR' "Installation de ${app} Impossible!"
             exit 1
           fi
         fi ;;
      'yum' )
         if [[ ! $(rpm -qi "${app}" 2> /dev/null) && $(command -v ${app} 2> /dev/null) ]]
         then
           echo -e "\n Installation de ${app} en cours \n"
           yum check-update > /dev/null
	   if [[ $(yum install -qy ${app}) ]]
           then
             alert_info 'INFO' "Installation de ${app} réussie"
           else
             alert_info 'ERREUR' "Installation de ${app} Impossible!"
             exit 1
           fi
         fi ;;
    esac
  fi
done

# GetOps
while getopts "hv" arguments
do
  case "${arguments}" in
    h)
      usage 
      ;;
    v)
      version 
      ;;
    *)
      alert_info 'ERREUR' 'argument non valide'
      usage 
      ;;
  esac
done

# Menu disk
echo -e "\n Merci de brancher la clé USB \n"
read -p "Taper sur entrée pour valider"
clear

# Scan des disques sur le système
devices=$(lsblk -lnd -I 8 -o NAME)

d_tab=()
d_count="0"

for dev in ${devices}
do
  d_tab[$d_count]="${dev}"
  (( d_count++ ))
done

#Choix du disque USB
lsblk -ld -I 8 -o NAME,TYPE,SIZE,MODEL
echo -e "\n Nom du disque exemple [ sdx ] \n"
read -p "Disque : " disk

# Regex
regex="^[s][d][a-z]$"

if [[ -z ${disk} ]]
then
  echo -e "\n Champ vide ! \n"
  exit 1
elif ! [[ ${disk} =~ ${regex} ]]
then
  echo -e "\n Erreur de saisie \n"
  exit 1
fi

b_ch="0"

for i in ${d_tab[@]}
do
  if [[ ${i} == ${disk} ]]
  then
    (( b_ch++ ))
  fi
done

if [[ ${b_ch} == "0" ]]
then
  echo -e "\n Erreur : Le périphérique ${disk} n'est pas présent dans le système! \n"
  exit 1
fi

# Menu
echo "Menu de configurations"
echo "----------------------"
PS3='Votre choix: '
options=('Install Ventoy' 'Remove Ventoy' 'Reinstall Ventoy' 'Update Ventoy' 'Add ISO' 'Remove ISO' 'ISO Persistence' 'Start in Hypervisor' 'Quit')
select opt in "${options[@]}"
do
  case $opt in
    'Install Ventoy')
      # demonter la clé
      umount -l /dev/${disk}* > /dev/null 2>&1
      if_installed_pc
      if_installed_usb
      break
      ;;
    'Remove Ventoy')
      umount -l /dev/${disk}* > /dev/null 2>&1
      ventoy_remove
      break
      ;;
    'Reinstall Ventoy')
      umount -l /dev/${disk}* > /dev/null 2>&1
      ventoy_reinstall
      break
      ;;
    'Update Ventoy')
      umount -l /dev/${disk}* > /dev/null 2>&1
      ventoy_update
      break
      ;;
    'Add ISO')
      umount -l /dev/${disk}* > /dev/null 2>&1
      ventoy_add_iso
      break      
      ;;
    'Remove ISO')
      umount -l /dev/${disk}* > /dev/null 2>&1
      ventoy_remove_iso
      break      
      ;;
    'ISO Persistence')
      ventoy_persist_iso
      break      
      ;;
    'Start in Hypervisor')
      ventoy_start_virtualbox
      break      
      ;;
    'Quit')
      alert_info 'INFO' 'Fin du script'
      exit 1
      ;;
    *)
      echo "Option invalide : ${REPLY}"
      ;;
  esac
done

# Effacer les traces
#trap clean_exit err exit

alert_info 'INFO' 'Fin du script'
