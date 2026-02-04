#!/bin/bash

# ====================================================================
# SCRIPT : sysadmin-tools.sh
# DESCRIPTION : Menu centralisé pour lancer tous les outils d'admin.
# AUTEUR : Val
# VERSION : 1.0
# ====================================================================

# --- CONFIGURATION ---
LOG_FILE="./sysadmin-tools.log"

# Liste des scripts nécessaires
SCRIPTS=("backup.sh" "monitor.sh" "create-users.sh" "cleanup.sh" "check-services.sh")

# Couleurs
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 1. VÉRIFICATION PRÉALABLE (6.3) ---
# On vérifie que tous les scripts sont là avant de lancer le menu
check_scripts() {
    MISSING=0
    for script in "${SCRIPTS[@]}"; do
        if [ ! -f "./$script" ]; then
            echo -e "${RED}Erreur : Le script $script est introuvable !${NC}"
            MISSING=1
        elif [ ! -x "./$script" ]; then
            echo -e "${YELLOW}Correction permissions : chmod +x $script${NC}"
            chmod +x "./$script"
        fi
    done

    if [ $MISSING -eq 1 ]; then
        echo -e "${RED}Certains outils manquent. Vérifiez votre dossier.${NC}"
        exit 1
    fi
}

# --- FONCTION DE LOG (6.3) ---
log_usage() {
    local TOOL=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Outil lancé : $TOOL par $USER" >> "$LOG_FILE"
}

# --- PAUSE ---
pause() {
    echo ""
    read -p "Appuyez sur [Entrée] pour revenir au menu..."
}

# --- BOUCLE PRINCIPALE ---
check_scripts

while true; do
    clear
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}      🛠️  OUTILS D'ADMINISTRATION v1.0      ${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo -e "1. 💾 Sauvegarde de répertoire"
    echo -e "2. 📊 Monitoring système"
    echo -e "3. 👥 Créer des utilisateurs (Admin)"
    echo -e "4. 🧹 Nettoyage système (Admin)"
    echo -e "5. 🩺 Vérifier les services"
    echo -e "6. 🚪 Quitter"
    echo -e "${CYAN}=============================================${NC}"
    read -p "Votre choix : " CHOIX

    case $CHOIX in
        1)
            echo -e "\n${BLUE}--- SAUVEGARDE ---${NC}"
            read -p "Quel dossier sauvegarder ? (ex: /home/val/Images) : " SRC
            if [ -d "$SRC" ]; then
                log_usage "Backup"
                ./backup.sh "$SRC"
            else
                echo -e "${RED}Dossier invalide.${NC}"
            fi
            pause
            ;;
        2)
            echo -e "\n${BLUE}--- MONITORING ---${NC}"
            echo "1. Affichage direct"
            echo "2. Générer un rapport (-r)"
            read -p "Choix : " MON_OPT
            log_usage "Monitor"
            if [ "$MON_OPT" == "2" ]; then
                ./monitor.sh -r
            else
                ./monitor.sh
            fi
            pause
            ;;
        3)
            echo -e "\n${BLUE}--- CRÉATION UTILISATEURS (Sudo requis) ---${NC}"
            read -p "Nom du fichier CSV (ex: users.csv) : " CSV
            read -p "Mode suppression ? (o/n) : " DEL
            
            log_usage "Create-Users"
            if [ "$DEL" == "o" ]; then
                sudo ./create-users.sh "$CSV" -d
            else
                sudo ./create-users.sh "$CSV"
            fi
            pause
            ;;
        4)
            echo -e "\n${BLUE}--- NETTOYAGE SYSTÈME (Sudo requis) ---${NC}"
            echo "1. Simulation (Dry-run)"
            echo "2. Nettoyage REEL (Force)"
            read -p "Choix : " CLEAN_OPT
            
            log_usage "Cleanup"
            if [ "$CLEAN_OPT" == "2" ]; then
                sudo ./cleanup.sh -f
            else
                sudo ./cleanup.sh
            fi
            pause
            ;;
        5)
            echo -e "\n${BLUE}--- SANTÉ DES SERVICES ---${NC}"
            echo "1. Vérification simple"
            echo "2. Mode Surveillance continue (Watch)"
            echo "3. Tenter de redémarrer les services HS"
            read -p "Choix : " SERV_OPT

            log_usage "Services"
            case $SERV_OPT in
                2) ./check-services.sh --watch ;;
                3) sudo ./check-services.sh -r ;;
                *) ./check-services.sh ;;
            esac
            pause
            ;;
        6)
            echo -e "${GREEN}Au revoir ! 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide.${NC}"
            sleep 1
            ;;
    esac
done
