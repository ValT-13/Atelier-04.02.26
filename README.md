# 🛠️ Atelier Bash - Automatisation Système

Bienvenue dans ma suite d'outils d'administration système pour Linux (Debian).
Ce projet regroupe des scripts Bash permettant d'automatiser les tâches courantes de maintenance, de surveillance et de gestion des utilisateurs.

## 📂 Structure du projet

| Dossier | Script | Description |
| :--- | :--- | :--- |
| **01_Sauvegarde** | `backup.sh` | Système de sauvegarde avec horodatage et **rotation automatique** (garde les 7 derniers). |
| **02_Monitoring** | `monitor.sh` | Tableau de bord temps réel (CPU, RAM, Disque) avec alertes couleurs et rapports. |
| **03_Gestion_Users** | `create-users.sh` | Création massive d'utilisateurs depuis CSV, génération de mots de passe et suppression. |
| **04_Nettoyage** | `cleanup.sh` | Nettoyeur système (Logs, Cache APT, Tmp) avec mode **Dry-Run** (simulation). |
| **05_Services** | `check-services.sh` | Surveillance des services critiques (SSH, Apache, etc.) avec redémarrage automatique. |
| **06_Menu_Global** | `sysadmin-tools.sh` | **Menu centralisé** interactif pour lancer tous les outils depuis une seule interface. |

## 🚀 Utilisation

### 1. Lancer le Menu Global (Recommandé)
C'est le point d'entrée principal pour utiliser tous les outils sans taper de commandes complexes.
```bash
./06_Menu_Global/sysadmin-tools.sh

### 2. Utilisation individuelle des scripts
Sauvegarde :
```
BACH
./01_Sauvegarde/backup.sh /dossier/a/sauvegarder
```
Monitoring :
```
./02_Monitoring/monitor.sh       # Vue directe
./02_Monitoring/monitor.sh -r    # Générer un rapport
```
Gestion Utilisateurs (Admin) :
```
sudo ./03_Gestion_Users/create-users.sh liste.csv      # Création
sudo ./03_Gestion_Users/create-users.sh liste.csv -d   # Suppression
```
Nettoyage (Admin) :
```
sudo ./04_Nettoyage/cleanup.sh      # Simulation (Sans risque)
sudo ./04_Nettoyage/cleanup.sh -f   # Nettoyage réel (Force)
```
Vérification Services :
```
./05_Services/check-services.sh --watch   # Mode surveillance continue
```
---
SB04E08-Atelier Bash - Automatisation de l'administration système