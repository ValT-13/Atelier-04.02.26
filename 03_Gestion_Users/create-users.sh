#!/bin/bash

# ====================================================================
# SCRIPT : create-users.sh
# DESCRIPTION : Création massive d'utilisateurs depuis un CSV
#               avec gestion des groupes et mots de passe.
# USAGE : sudo ./create-users.sh <fichier.csv> [-d|--delete]
# ====================================================================

# --- CONFIGURATION ---
LOG_FILE="./user-creation.log"
PASSWORD_FILE="./users_created.txt"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- VÉRIFICATION ROOT ---
# Pour créer des utilisateurs, il faut être root (sudo)
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Erreur : Ce script doit être exécuté avec sudo.${NC}"
    exit 1
fi

# --- FONCTION DE LOG ---
log_action() {
    local MSG=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" | tee -a "$LOG_FILE"
}

# --- VÉRIFICATION ARGUMENTS ---
CSV_FILE=$1
MODE="CREATE"

if [ -z "$CSV_FILE" ]; then
    echo "Usage : sudo $0 <fichier.csv> [-d pour supprimer]"
    exit 1
fi

if [ "$2" == "-d" ] || [ "$2" == "--delete" ]; then
    MODE="DELETE"
fi

if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED}Fichier CSV introuvable : $CSV_FILE${NC}"
    exit 1
fi

# Initialisation du fichier de mots de passe (si mode création)
if [ "$MODE" == "CREATE" ]; then
    echo "--- LISTE DES UTILISATEURS CRÉÉS LE $(date) ---" > "$PASSWORD_FILE"
    echo "Login | Mot de passe | Groupe" >> "$PASSWORD_FILE"
    echo "----------------------------------------------" >> "$PASSWORD_FILE"
fi

# --- LECTURE DU CSV ---
# IFS=, définit la virgule comme séparateur
# 'read' ignore la première ligne si on met un compteur ou une astuce,
# ici on teste si la ligne contient "prenom" pour sauter l'en-tête.
while IFS=, read -r prenom nom departement fonction; do
    
    # Nettoyage des retours chariot éventuels (problème fréquent CSV Windows)
    fonction=$(echo "$fonction" | tr -d '\r')
    
    # Ignorer l'en-tête
    if [ "$prenom" == "prenom" ]; then continue; fi

    # Génération du login : 1ère lettre prénom + nom (le tout en minuscule)
    LOGIN=$(echo "${prenom:0:1}${nom}" | tr '[:upper:]' '[:lower:]')
    
    # Génération du groupe (minuscule)
    GROUPE=$(echo "$departement" | tr '[:upper:]' '[:lower:]')

    # --- MODE SUPPRESSION ---
    if [ "$MODE" == "DELETE" ]; then
        if id "$LOGIN" &>/dev/null; then
            read -p "Voulez-vous VRAIMENT supprimer l'utilisateur $LOGIN ? (o/n) : " REP < /dev/tty
            if [[ "$REP" == "o" ]]; then
                userdel -r "$LOGIN" 2>/dev/null
                log_action "🗑️  Utilisateur supprimé : $LOGIN"
                echo -e "${YELLOW}Utilisateur $LOGIN supprimé.${NC}"
            fi
        else
            echo -e "${RED}L'utilisateur $LOGIN n'existe pas.${NC}"
        fi
        continue
    fi

    # --- MODE CRÉATION ---
    
    # 1. Création du groupe s'il n'existe pas
    if ! getent group "$GROUPE" > /dev/null; then
        groupadd "$GROUPE"
        log_action "Groupe créé : $GROUPE"
        echo -e "${YELLOW}Groupe ajouté : $GROUPE${NC}"
    fi

    # 2. Création de l'utilisateur
    if id "$LOGIN" &>/dev/null; then
        echo -e "${YELLOW}L'utilisateur $LOGIN existe déjà. Ignoré.${NC}"
    else
        # Génération mot de passe aléatoire (12 caractères)
        PASSWORD=$(openssl rand -base64 12)
        
        # Création (useradd : -m pour home, -s pour shell, -g pour groupe, -c pour commentaire)
        useradd -m -s /bin/bash -g "$GROUPE" -c "$prenom $nom ($fonction)" "$LOGIN"
        
        # Attribution du mot de passe
        echo "$LOGIN:$PASSWORD" | chpasswd

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Utilisateur créé : $LOGIN ($GROUPE)${NC}"
            log_action "SUCCESS : User $LOGIN created (Grp: $GROUPE)"
            
            # Sauvegarde dans le fichier secret
            echo "$LOGIN | $PASSWORD | $GROUPE" >> "$PASSWORD_FILE"
        else
            echo -e "${RED}❌ Erreur création : $LOGIN${NC}"
            log_action "ERROR : Failed to create $LOGIN"
        fi
    fi

done < "$CSV_FILE"

if [ "$MODE" == "CREATE" ]; then
    echo ""
    echo -e "${GREEN}Terminé ! Les mots de passe sont dans : $PASSWORD_FILE${NC}"
    echo -e "Consultez le journal dans : $LOG_FILE"
fi
