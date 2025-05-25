#!/bin/bash
#########################################################
# Updated by Vaudois
# Compatible with Ubuntu 20/22, Ubuntu 18 support removed
# Adapted for ARM architectures
#########################################################

# Color codes for output
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

echo
echo -e "$CYAN => Checking prerequisites: $COL_RESET"

# Check Ubuntu version
DISTRO=""
if [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/20\.04\.[0-9]/20.04/')" == "Ubuntu 20.04 LTS" ]]; then
    DISTRO=20
    sudo chmod g-w /etc /etc/default /usr
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/22\.04\.[0-9]/22.04/')" == "Ubuntu 22.04 LTS" ]]; then
    DISTRO=22
    sudo chmod g-w /etc /etc/default /usr
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/')" == "Ubuntu 16.04 LTS" ]]; then
    echo -e "$RED This script does not support Ubuntu 16.04. Supported versions: Ubuntu 20.04 and 22.04$COL_RESET"
    echo -e "$RED Stopping installation!$COL_RESET"
    exit 1
elif [[ "$(lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/')" == "Ubuntu 18.04 LTS" ]]; then
    echo -e "$RED This script no longer supports Ubuntu 18.04 (end of standard support). Please upgrade to Ubuntu 20.04 or 22.04$COL_RESET"
    echo -e "$RED Stopping installation!$COL_RESET"
    exit 1
else
    echo -e "$RED Unsupported Ubuntu version. This script supports only Ubuntu 20.04 and 22.04$COL_RESET"
    echo -e "$RED Stopping installation!$COL_RESET"
    exit 1
fi

# Check architecture
ARCHITECTURE=$(uname -m)
if [[ "$ARCHITECTURE" != "x86_64" && ! "$ARCHITECTURE" =~ ^arm ]]; then
    echo -e "$RED Yiimp installation script supports only x86_64 and ARM (all variants) architectures.$COL_RESET"
    echo -e "$RED Your architecture is $ARCHITECTURE$COL_RESET"
    exit 1
fi

# Check lsb_release command
if ! command -v lsb_release >/dev/null 2>&1; then
    echo -e "$RED The lsb_release command is not found. Please install the lsb-release package.$COL_RESET"
    exit 1
fi

echo -e "$GREEN Done...$COL_RESET"
