#!/bin/bash

ventoy_update() {
  # -u : Mise à jour 
  bash /opt/ventoy-*/Ventoy2Disk.sh -u /dev/"${disk}"
}
