#!/bin/bash

# ====================================================================
# SCRIPT : backup.sh
# DESCRIPTION : Sauvegarde un dossier en .tar.gz avec horodatage
#               et gestion de la rotation (garde les 7 derniers).
# AUTEUR : Val
# DATE : Février 2026
# ====================================================================

# --- CONFIGURATION ---
# On place les backups dans un sous-dossier pour ne pas polluer la racine
DEST_DIR="$HOME/Atelier_Bash_Automatisation/backups"
LOG_FILE="$HOME/Atelier_Bash_Automatisation/backup.log"
RETENTION=7  # Nombre de sauvegardes à garder

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- FONCTION D'AIDE ---
usage() {
    echo -e "${YELLOW}Usage : $0 <dossier_a_sauvegarder>${NC}"
    echo "Exemple : $0 /home/val/mon_projet"
    exit 1
}

# --- FONCTION DE LOG ---
log_message() {
    local TYPE=$1
    local MSG=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$TYPE] $MSG" >> "$LOG_FILE"
}

# 1. Vérification des arguments
if [ -z "$1" ]; then
    usage
fi

SOURCE_DIR="$1"

# 2. Vérification que la source existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Erreur : Le dossier source '$SOURCE_DIR' n'existe pas.${NC}"
    log_message "ERROR" "Tentative de backup échouée : source '$SOURCE_DIR' introuvable."
    exit 1
fi

# 3. Préparation du dossier de destination
if [ ! -d "$DEST_DIR" ]; then
    echo "Création du dossier de backup : $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# 4. Vérification de l'espace disque (Simplifié)
# On vérifie juste si la partition n'est pas pleine à 100%
DISK_USAGE=$(df "$DEST_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -ge 95 ]; then
    echo -e "${RED}Attention : Espace disque critique ($DISK_USAGE%).${NC}"
    log_message "WARNING" "Espace disque faible sur la destination."
fi

# --- SAUVEGARDE ---
DATE_FORMAT=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="backup_${DATE_FORMAT}.tar.gz"
FULL_PATH="$DEST_DIR/$ARCHIVE_NAME"

echo "Sauvegarde de '$SOURCE_DIR' en cours..."

# Création de l'archive (c=create, z=gzip, f=file)
# 2>> permet d'envoyer les erreurs techniques dans le fichier de log
tar -czf "$FULL_PATH" "$SOURCE_DIR" 2>> "$LOG_FILE"

# Vérification du succès de la commande tar ($? = code de retour)
if [ $? -eq 0 ]; then
    SIZE=$(du -h "$FULL_PATH" | cut -f1)
    echo -e "${GREEN}✅ Sauvegarde réussie : $ARCHIVE_NAME ($SIZE)${NC}"
    log_message "SUCCESS" "Backup créé : $ARCHIVE_NAME ($SIZE)"
else
    echo -e "${RED}❌ Échec de la sauvegarde.${NC}"
    log_message "ERROR" "La commande tar a échoué pour $SOURCE_DIR"
    exit 1
fi

# --- ROTATION DES SAUVEGARDES (1.3) ---
# On compte les fichiers de backup
COUNT=$(ls -1 "$DEST_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$COUNT" -gt "$RETENTION" ]; then
    echo "Nettoyage des vieilles sauvegardes (Plus de $RETENTION fichiers)..."
    
    # Explication de la commande magique :
    # ls -t : trier par date (récent en premier)
    # tail -n +8 : prendre tout à partir de la 8ème ligne (donc les vieux)
    # xargs rm : passer ces noms à la commande rm
    ls -t "$DEST_DIR"/backup_*.tar.gz | tail -n +$(($RETENTION + 1)) | xargs rm --
    
    echo -e "${YELLOW}🧹 Nettoyage effectué.${NC}"
    log_message "INFO" "Rotation effectuée : anciennes sauvegardes supprimées."
fi

exit 0
