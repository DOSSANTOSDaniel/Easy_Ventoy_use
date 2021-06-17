#!/bin/bash

install_usb() {
  # -i : Installation, mais si la clé contient déjà Ventoy alors erreur
  # -s : Active la compatibilité de secure boot
  # -g : Utilisation de partitions en GPT
  bash /opt/ventoy-*/Ventoy2Disk.sh -i -s -g /dev/"${disk}"
}
