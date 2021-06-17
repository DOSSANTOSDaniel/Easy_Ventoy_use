#!/bin/bash

install_pc() {
  # Téléchargement
  wget -c -O /opt/ventoy.tar.gz --progress='bar' https://github.com/ventoy/Ventoy/releases/download/v"${version}"/ventoy-"${version}"-linux.tar.gz
    
  test -f /opt/ventoy.tar.gz || (alert_info 'ERREUR' "Erreur de téléchargement" && exit 1)
 
  # Decompression : boot, tool, ventoy, plugin, CreatePersistentImg.sh, Ventoy2Disk.sh.
  if (tar -xvf /opt/ventoy.tar.gz -C /opt)
  then
    rm -rf /opt/ventoy.tar.gz
  else 
    alert_info 'ERREUR' "Erreur de décompression"
    exit 1
  fi
}
