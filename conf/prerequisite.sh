#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# Modified by Vaudois
# Updated for Ubuntu 22.04 compatibility, removed Ubuntu 18.04 support
# Changes:
# - Added support for Ubuntu 22.04 (DISTRO=22)
# - Removed support for Ubuntu 18.04 (DISTRO=18) as it is no longer supported
# - Improved error handling and logging
# - Maintained compatibility with Ubuntu 20.04
#####################################################

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

# Log file for debugging
LOG_FILE="/var/log/yiimp_install.log"

# Function to log messages
function log_message {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null
}

echo
echo -e "$CYAN => Checking prerequisites : $COL_RESET"
log_message "Starting prerequisite checks"

# Check Ubuntu version
DISTRO=""
if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/20\.04\.[0-9]/20.04/'`" == "Ubuntu 20.04 LTS" ]; then
    DISTRO=20
    sudo chmod g-w /etc /etc/default /usr
    log_message "Detected Ubuntu 20.04 (DISTRO=20)"
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/22\.04\.[0-9]/22.04/'`" == "Ubuntu 22.04 LTS" ]; then
    DISTRO=22
    sudo chmod g-w /etc /etc/default /usr
    log_message "Detected Ubuntu 22.04 (DISTRO=22)"
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/'`" == "Ubuntu 16.04 LTS" ]; then
    DISTRO=16
    echo -e "$RED This script does not support Ubuntu 16.04. Supported versions are Ubuntu 20.04 and 22.04$COL_RESET"
    echo -e "$RED Stopping installation now!$COL_RESET"
    log_message "Unsupported Ubuntu 16.04 detected, exiting"
    exit 1
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/'`" == "Ubuntu 18.04 LTS" ]; then
    echo -e "$RED This script no longer supports Ubuntu 18.04 as it has reached end of standard support. Please upgrade to Ubuntu 20.04 or 22.04$COL_RESET"
    echo -e "$RED Stopping installation now!$COL_RESET"
    log_message "Unsupported Ubuntu 18.04 detected, exiting"
    exit 1
else
    echo -e "$RED Unsupported Ubuntu version. This script supports Ubuntu 20.04 and 22.04 only$COL_RESET"
    echo -e "$RED Stopping installation now!$COL_RESET"
    log_message "Unsupported Ubuntu version detected: $(lsb_release -d), exiting"
    exit 1
fi

# Check architecture
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
    if [ -z "$ARM" ]; then
        echo -e "$RED Yiimp Install Script only supports x86_64 and will not work on other architectures, like ARM or 32-bit OS.$COL_RESET"
        echo -e "$RED Your architecture is $ARCHITECTURE$COL_RESET"
        log_message "Unsupported architecture detected: $ARCHITECTURE, exiting"
        exit 1
    fi
    log_message "ARM architecture detected, proceeding with ARM flag"
fi

# Verify lsb_release command
if ! command -v lsb_release >/dev/null 2>&1; then
    echo -e "$RED lsb_release command not found. Please ensure lsb-release package is installed.$COL_RESET"
    log_message "lsb_release command not found, exiting"
    exit 1
fi

echo -e "$GREEN Done...$COL_RESET"
log_message "Prerequisite checks completed successfully"
