#!/bin/bash

# ====================================================================
# SCRIPT : check-services.sh
# DESCRIPTION : Vérifie l'état des services, relance si nécessaire,
#               génère un rapport JSON et permet le monitoring en direct.
# USAGE : ./check-services.sh [--watch] [-r|--restart]
# ====================================================================

# --- CONFIGURATION ---
CONF_FILE="services.conf"
JSON_FILE="services_status.json"
RESTART_MODE=false
WATCH_MODE=false

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- GESTION DES ARGUMENTS ---
for arg in "$@"; do
    case $arg in
        --watch) WATCH_MODE=true ;;
        -r|--restart) RESTART_MODE=true ;;
    esac
done

# --- FONCTION PRINCIPALE ---
check_services() {
    # Si mode watch, on nettoie l'écran à chaque tour
    if [ "$WATCH_MODE" = true ]; then clear; fi

    echo -e "${BLUE}=== MONITORING DES SERVICES ($(date '+%H:%M:%S')) ===${NC}"
    echo -e "Service       | État        | Démarrage | Action"
    echo "--------------------------------------------------------"

    # Initialisation du JSON (On le fait à la main, c'est du bricolage Bash)
    echo "[" > "$JSON_FILE"
    FIRST_LINE=true
    
    ACTIVE_COUNT=0
    INACTIVE_COUNT=0

    # Lecture du fichier ligne par ligne
    while read -r SERVICE || [ -n "$SERVICE" ]; do
        # Sauter les lignes vides
        if [ -z "$SERVICE" ]; then continue; fi

        # 1. Vérification du statut
        if systemctl is-active --quiet "$SERVICE"; then
            STATUS="${GREEN}ACTIF${NC}"
            STATUS_JSON="active"
            ((ACTIVE_COUNT++))
            MSG="-"
        else
            STATUS="${RED}INACTIF${NC}"
            STATUS_JSON="inactive"
            ((INACTIVE_COUNT++))
            MSG="${RED}⚠️ ALERTE${NC}"

            # 5.3 Option Redémarrage automatique
            if [ "$RESTART_MODE" = true ]; then
                echo "Tentative de redémarrage de $SERVICE..."
                sudo systemctl start "$SERVICE" 2>/dev/null
                if systemctl is-active --quiet "$SERVICE"; then
                     STATUS="${GREEN}RESTAURÉ${NC}"
                     MSG="${GREEN}Relancé avec succès${NC}"
                     STATUS_JSON="restarted"
                else
                     MSG="${RED}Échec redémarrage${NC}"
                fi
            fi
        fi

        # 2. Vérification "Enabled" (Activé au démarrage)
        if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
            BOOT="Oui"
        else
            BOOT="Non"
        fi

        # Affichage Ligne
        printf "%-13s | %-18b | %-9s | %b\n" "$SERVICE" "$STATUS" "$BOOT" "$MSG"

        # Ajout au JSON (gestion de la virgule entre les objets)
        if [ "$FIRST_LINE" = true ]; then FIRST_LINE=false; else echo "," >> "$JSON_FILE"; fi
        echo "  { \"service\": \"$SERVICE\", \"status\": \"$STATUS_JSON\", \"boot_enabled\": \"$BOOT\", \"date\": \"$(date)\" }" >> "$JSON_FILE"

    done < "$CONF_FILE"

    # Clôture du JSON
    echo "]" >> "$JSON_FILE"

    echo "--------------------------------------------------------"
    echo -e "Résumé : ${GREEN}$ACTIVE_COUNT Actifs${NC} | ${RED}$INACTIVE_COUNT Inactifs${NC}"
    echo -e "Rapport JSON généré : $JSON_FILE"
}

# --- BOUCLE DE MONITORING (5.4) ---
if [ "$WATCH_MODE" = true ]; then
    echo "👀 Mode Surveillance activé (Ctrl+C pour arrêter)"
    while true; do
        check_services
        sleep 5 # J'ai mis 5s au lieu de 30s pour que tu testes plus vite !
    done
else
    check_services
fi
