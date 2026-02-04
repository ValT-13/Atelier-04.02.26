#!/bin/bash

# ====================================================================
# SCRIPT : cleanup.sh
# DESCRIPTION : Nettoyeur système intelligent (Logs, Tmp, Cache, Trash)
# USAGE : sudo ./cleanup.sh [-f|--force] [-d jours]
# ====================================================================

# --- CONFIGURATION PAR DÉFAUT ---
LOG_FILE="/var/log/cleanup.log"
DAYS_TMP=7
DAYS_LOGS=30
DRY_RUN=true
FORCE=false

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- VÉRIFICATION ROOT ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Erreur : Ce script doit être exécuté avec sudo (accès /var/log et /tmp).${NC}"
    exit 1
fi

# --- GESTION DES ARGUMENTS ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=true; DRY_RUN=false ;;
        -d|--days) DAYS_TMP="$2"; DAYS_LOGS="$2"; shift ;; # On applique l'âge aux logs et tmp
        *) echo "Option inconnue: $1"; exit 1 ;;
    esac
    shift
done

# --- FONCTION DE LOG ---
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# --- FONCTION DE CALCUL D'ESPACE ---
get_size() {
    # $1 = chemin, $2 = pattern (optionnel)
    if [ -z "$2" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        find "$1" -name "$2" -type f -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1
    fi
}

# --- AFFICHAGE DE L'ÉTAT INITIAL ---
clear
echo -e "${BLUE}=== NETTOYEUR SYSTÈME AUTOMATIQUE ===${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🚧 MODE SIMULATION (DRY-RUN) - Rien ne sera supprimé.${NC}"
    echo "Utilisez -f ou --force pour supprimer réellement."
else
    echo -e "${RED}⚠️  MODE NETTOYAGE ACTIF - Les fichiers seront supprimés !${NC}"
fi

DISK_BEFORE=$(df / | tail -1 | awk '{print $4}')
echo -e "Espace disque disponible avant : ${GREEN}${DISK_BEFORE}K${NC}"
echo "---------------------------------------------------"

TOTAL_CLEANED=0

# --- 1. NETTOYAGE /TMP (> 7 jours ou argument -d) ---
echo -e "${BLUE}[1/4] Analyse du dossier /tmp (Plus vieux que $DAYS_TMP jours)...${NC}"
COUNT_TMP=$(find /tmp -type f -mtime +$DAYS_TMP 2>/dev/null | wc -l)

if [ "$COUNT_TMP" -gt 0 ]; then
    SIZE_TMP=$(find /tmp -type f -mtime +$DAYS_TMP -exec du -ch {} + | tail -1 | cut -f1)
    echo " -> $COUNT_TMP fichiers trouvés ($SIZE_TMP)."
    
    if [ "$FORCE" = true ]; then
        find /tmp -type f -mtime +$DAYS_TMP -delete
        log_action "Nettoyage /tmp : $COUNT_TMP fichiers supprimés."
        echo -e "${GREEN} -> Supprimés.${NC}"
    fi
else
    echo " -> Rien à nettoyer."
fi

# --- 2. NETTOYAGE LOGS COMPRESSÉS .GZ (> 30 jours ou argument -d) ---
echo -e "${BLUE}[2/4] Analyse des logs archivés /var/log (*.gz > $DAYS_LOGS jours)...${NC}"
COUNT_LOGS=$(find /var/log -name "*.gz" -mtime +$DAYS_LOGS 2>/dev/null | wc -l)

if [ "$COUNT_LOGS" -gt 0 ]; then
    SIZE_LOGS=$(find /var/log -name "*.gz" -mtime +$DAYS_LOGS -exec du -ch {} + | tail -1 | cut -f1)
    echo " -> $COUNT_LOGS archives trouvées ($SIZE_LOGS)."
    
    if [ "$FORCE" = true ]; then
        find /var/log -name "*.gz" -mtime +$DAYS_LOGS -delete
        log_action "Nettoyage Logs : $COUNT_LOGS fichiers supprimés."
        echo -e "${GREEN} -> Supprimés.${NC}"
    fi
else
    echo " -> Rien à nettoyer."
fi

# --- 3. CACHE APT ---
echo -e "${BLUE}[3/4] Analyse du cache APT...${NC}"
SIZE_APT=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)
echo " -> Taille du cache : $SIZE_APT"

if [ "$FORCE" = true ]; then
    apt-get clean
    log_action "Nettoyage APT : Cache vidé ($SIZE_APT)."
    echo -e "${GREEN} -> Cache vidé.${NC}"
fi

# --- 4. CORBEILLES UTILISATEURS ---
echo -e "${BLUE}[4/4] Analyse des corbeilles utilisateurs (/home/*/.local/share/Trash)...${NC}"
# On cherche tous les dossiers Trash
TRASH_DIRS=$(ls -d /home/*/.local/share/Trash/files 2>/dev/null)

for DIR in $TRASH_DIRS; do
    USER=$(echo "$DIR" | cut -d'/' -f3)
    COUNT_TRASH=$(ls -1 "$DIR" | wc -l)
    
    if [ "$COUNT_TRASH" -gt 0 ]; then
        SIZE_TRASH=$(du -sh "$DIR" | cut -f1)
        echo " -> Corbeille de $USER : $COUNT_TRASH fichiers ($SIZE_TRASH)."
        
        if [ "$FORCE" = true ]; then
            rm -rf "$DIR"/*
            log_action "Nettoyage Trash $USER : $SIZE_TRASH libérés."
            echo -e "${GREEN} -> Vidée.${NC}"
        fi
    else
        echo " -> Corbeille de $USER : Vide."
    fi
done

# --- RAPPORT FINAL ---
echo "---------------------------------------------------"
DISK_AFTER=$(df / | tail -1 | awk '{print $4}')
DIFF=$((DISK_AFTER - DISK_BEFORE))

if [ "$FORCE" = true ]; then
    echo -e "${GREEN}✅ NETTOYAGE TERMINÉ.${NC}"
    echo -e "Espace disque actuel : ${DISK_AFTER}K"
    echo -e "Gain estimé : ${YELLOW}${DIFF}K${NC} (libérés ou fluctuants)"
    log_action "Fin du nettoyage. Espace libre : $DISK_AFTER"
else
    echo -e "${YELLOW}🚧 FIN DE SIMULATION.${NC}"
    echo "Lancez avec 'sudo ./cleanup.sh -f' pour nettoyer réellement."
    echo "Ajoutez '-d 0' pour forcer la suppression de TOUT (fichiers récents inclus) pour tester."
fi
