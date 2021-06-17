#!/bin/bash

ventoy_persist_iso() {
# installation de jq
apt-get install -qy jq
  
# Persistence
mkdir ${v_dir}/ventoy
  
mount_and_list_iso

if [[ $(find ${v_dir} -type f -name "*.iso" | wc -l) -le "1" ]]
then
  alert_info 'INFO' "Il y a pas d'ISO's dans le dossier ventoy"
  exit 1
fi
ls -l ${v_dir} | awk '{print $9}'   ################################## mettre menu
read -r -p "Nom de l'ISO : " iso_pers
read -r -p "Taille de la persistance : " pers
  
if [[ ! ${pers} =~ [[:digit:]] ]]
then
  alert_info 'ERREUR' 'Erreur de saisie'
  exit 1
fi
  
bash /opt/ventoy-"${version}"/CreatePersistentImg.sh -s "${pers}"
mv persistence.dat ${v_dir}/"${iso_pers}".dat
  
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
