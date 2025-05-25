#!/bin/bash
#####################################################
# Source : https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Mis à jour par cryptopool.builders pour un usage crypto
# Modifié par Vaudois
# Compatible avec Ubuntu 22.04, support Ubuntu 18.04 supprimé
# Adapté pour l'architecture ARM
#####################################################

# Définition des codes de couleur pour l'affichage
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

# Fichier de journalisation pour le débogage
LOG_FILE="/var/log/yiimp_install.log"

# Fonction pour enregistrer les messages dans le journal
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null
}

echo
echo -e "$CYAN => Vérification des prérequis : $COL_RESET"
log_message "Démarrage des vérifications des prérequis"

# Vérification de la version d'Ubuntu
DISTRO=""
if [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/20\.04\.[0-9]/20.04/')" == "Ubuntu 20.04 LTS" ]]; then
    DISTRO=20
    sudo chmod g-w /etc /etc/default /usr
    log_message "Ubuntu 20.04 détecté (DISTRO=20)"
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/22\.04\.[0-9]/22.04/')" == "Ubuntu 22.04 LTS" ]]; then
    DISTRO=22
    sudo chmod g-w /etc /etc/default /usr
    log_message "Ubuntu 22.04 détecté (DISTRO=22)"
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/')" == "Ubuntu 16.04 LTS" ]]; then
    echo -e "$RED Ce script ne prend pas en charge Ubuntu 16.04. Versions supportées : Ubuntu 20.04 et 22.04$COL_RESET"
    echo -e "$RED Arrêt de l'installation !$COL_RESET"
    log_message "Ubuntu 16.04 non supporté détecté, arrêt"
    exit 1
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/')" == "Ubuntu 18.04 LTS" ]]; then
    echo -e "$RED Ce script ne prend plus en charge Ubuntu 18.04 (fin du support standard). Veuillez passer à Ubuntu 20.04 ou 22.04$COL_RESET"
    echo -e "$RED Arrêt de l'installation !$COL_RESET"
    log_message "Ubuntu 18.04 non supporté détecté, arrêt"
    exit 1
else
    echo -e "$RED Version d'Ubuntu non supportée. Ce script prend en charge uniquement Ubuntu 20.04 et 22.04$COL_RESET"
    echo -e "$RED Arrêt de l'installation !$COL_RESET"
    log_message "Version d'Ubuntu non supportée détectée : $(lsb_release -d), arrêt"
    exit 1
fi

# Vérification de l'architecture
ARCHITECTURE=$(uname -m)
if [[ "$ARCHITECTURE" != "x86_64" && "$ARCHITECTURE" != "arm64" ]]; then
    echo -e "$RED Le script d'installation Yiimp prend en charge uniquement les architectures x86_64 et ARM.$COL_RESET"
    echo -e "$RED Votre architecture est $ARCHITECTURE$COL_RESET"
    log_message "Architecture non supportée détectée : $ARCHITECTURE, arrêt"
    exit 1
fi
log_message "Architecture détectée : $ARCHITECTURE"

# Vérification de la commande lsb_release
if ! command -v lsb_release >/dev/null 2>&1; then
    echo -e "$RED La commande lsb_release est introuvable. Veuillez installer le paquet lsb-release.$COL_RESET"
    log_message "Commande lsb_release introuvable, arrêt"
    exit 1
fi

echo -e "$GREEN Terminé...$COL_RESET"
log_message "Vérifications des prérequis terminées avec succès"
