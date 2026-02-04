#!/bin/bash

# ====================================================================
# SCRIPT : monitor.sh
# DESCRIPTION : Affiche les métriques système (CPU, RAM, Disque)
#               avec des alertes couleurs et une option de rapport.
# ====================================================================

# --- CONFIGURATION ---
# On stocke les rapports dans un dossier dédié
REPORT_DIR="$HOME/Atelier_Bash_Automatisation/rapports"
REPORT_FILE="$REPORT_DIR/monitor_$(date +%Y%m%d).txt"

# --- COULEURS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- FONCTIONS ---

# Fonction pour choisir la couleur en fonction du seuil ( <70% vert, 70-85% jaune, >85% rouge)
colorize() {
    local VAL=$1
    # On enlève les décimales pour la comparaison
    local INT_VAL=${VAL%.*} 
    
    if [ "$INT_VAL" -ge 85 ]; then
        echo -e "${RED}${VAL}% (CRITIQUE)${NC}"
    elif [ "$INT_VAL" -ge 70 ]; then
        echo -e "${YELLOW}${VAL}% (ATTENTION)${NC}"
    else
        echo -e "${GREEN}${VAL}% (OK)${NC}"
    fi
}

# Fonction pour afficher une barre de séparation
separator() {
    echo "--------------------------------------------------------"
}

# --- COLLECTE DES DONNÉES ---

# 1. Infos de base
HOSTNAME=$(hostname)
DATE=$(date "+%Y-%m-%d %H:%M:%S")
UPTIME=$(uptime -p)

# 2. CPU Usage (Astuce : 100% - %Idle)
# Nécessite le paquet "procps" (souvent installé). Sinon on utilise top.
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}')
# Si awk échoue à cause du format français (virgule), on gère :
if [ -z "$CPU_IDLE" ]; then CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}'); fi
# Calcul simple via awk pour éviter bc
CPU_USAGE=$(awk "BEGIN {print 100 - $CPU_IDLE}")

# 3. Mémoire
# Récupération en Mo pour le calcul
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
# Calcul du pourcentage
MEM_PCT=$(( 100 * MEM_USED / MEM_TOTAL ))
# Conversion en Go pour l'affichage propre
MEM_INFO_HUMAN=$(free -h | grep Mem | awk '{print $3 "/" $2}')

# 4. Disque (Partition racine /)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d %)

# 5. Processus
PROCESS_COUNT=$(ps -e | wc -l)

# --- AFFICHAGE À L'ÉCRAN ---

clear
separator
echo -e "   📊  MONITEUR SYSTÈME - $HOSTNAME"
separator
echo -e "Date    : $DATE"
echo -e "Uptime  : $UPTIME"
separator
echo -e "🧠 PROCESSEUR (CPU) : $(colorize "$CPU_USAGE")"
echo -e "💾 MÉMOIRE (RAM)    : $(colorize "$MEM_PCT") [Utilisé: $MEM_INFO_HUMAN]"
echo -e "💿 DISQUE (Root /)  : $(colorize "$DISK_USAGE")"
echo -e "⚙️  PROCESSUS ACTIFS : $PROCESS_COUNT"
separator

echo -e "🏆 TOP 5 - CPU :"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6 | awk '{printf "%-6s %-20s %s\n", $1, $5"%", $3}'

echo ""
echo -e "🏆 TOP 5 - MÉMOIRE :"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6 | awk '{printf "%-6s %-20s %s\n", $1, $4"%", $3}'
separator

# --- GÉNÉRATION DU RAPPORT (Option 2.3) ---
# Si l'argument "report" ou "-r" est passé au script
if [[ "$1" == "report" || "$1" == "-r" ]]; then
    # Création du dossier si inexistant
    if [ ! -d "$REPORT_DIR" ]; then mkdir -p "$REPORT_DIR"; fi
    
    # Écriture dans le fichier (sans les couleurs)
    {
        echo "RAPPORT MONITORING - $DATE"
        echo "Serveur: $HOSTNAME"
        echo "---------------------------------"
        echo "CPU Usage : $CPU_USAGE%"
        echo "RAM Usage : $MEM_PCT% ($MEM_INFO_HUMAN)"
        echo "Disk Usage: $DISK_USAGE%"
        echo "Processus : $PROCESS_COUNT"
        echo "---------------------------------"
        echo "TOP 5 CPU:"
        ps -eo pid,cmd,%cpu --sort=-%cpu | head -6
    } >> "$REPORT_FILE"

    echo -e "${GREEN}✅ Rapport sauvegardé dans : $REPORT_FILE${NC}"
fi
