#!/bin/bash

ventoy_reinstall() {
# -I : Force l'installation de Ventoy même si Ventoy est déjà installé sur la clé USB
  bash /opt/ventoy-*/Ventoy2Disk.sh -I -s -g /dev/"${disk}"
}
