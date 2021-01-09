# Easy_Ventoy_use (En cours de fabrication)

## Rôle:

Ce script va permettre de faciliter l'utilisation de Ventoy.

## Détail des fonctionnalités :

1. Installation automatique de Ventoy sur une clé.
2. Mise à jour de Ventoy.
3. Ajout d'ISOs.
4. Supression d'ISOs.
5. Mise en place de la persistance sur certains isos.
6. Booter Ventoy sur VirtualBox.

## Usage:

```bash
./script_ventoy.sh -[h|v]
```
-h : Aide.
-v : Affiche la version.
               
## Contraintes et limitations:
*. Le script doit être executé en tant que root.
*. Au niveau de la fonction (Add ISO) on ne peut pas télécharger plusieurs fois le même ISO.

## Reste à faire
*. Code à faire pour la partie (other ISO), pour la copie utiliser "scp -p et -u pour supprimer le fichier source si besoin".
*. Création des dossiers redondants, revoir l'idempotence.
*. Revoir l'installation de JQ.
