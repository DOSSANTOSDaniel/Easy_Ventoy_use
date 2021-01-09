# Easy_Ventoy_use (En cours de fabrication)

## Rôle:

Ce script va permettre de faciliter l'utilisation de Ventoy.

## Détail des fonctionnalités :

1. Installation de Ventoy sur une clé USB.
2. Suppressition de Ventoy de la clé USB.
3. Réinstallation de ventoy sur une clé USB.
4. Mise à jour de Ventoy.
5. Ajout d'ISOs.
6. Supression d'ISOs.
7. Mise en place de la persistance sur certains isos.
8. Booter Ventoy sur VirtualBox.
9. Customisation de Ventoy (Pas encore implémenté).

## Usage:

```bash
./script_ventoy.sh -[h|v]

-h : Aide.
-v : Affiche la version.
```               
## Contraintes et limitations:
* Le script doit être executé en tant que root.
* Au niveau de la fonction (Add ISO) on ne peut pas télécharger plusieurs fois le même ISO.

## Reste à faire
* Code à faire pour la partie (other ISO), pour la copie utiliser "scp -p et -u pour supprimer le fichier source si besoin".
* Création des dossiers redondants, revoir l'idempotence.
* Revoir l'installation de JQ.
* Revoir les fonctions code redondants.
