#!/bin/bash
#################################################################################
# Author: Vaudois
#
# Program:
#   Check or create swap for this installation
#################################################################################

# Check and manage swap for compilation
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
MIN_SWAP_MB=4096  # Minimum swap required (4GB)
SWAP_FILE="/swapfile_yiimp"
CREATED_SWAP=false

# Disable all active swaps to avoid conflicts
echo "Disabling all active swap spaces..."
sudo swapoff -a 2>/dev/null

# Check available disk space (in MB) in the root directory
DISK_SPACE=$(df -m / | awk 'NR>1 {print $4}')

echo "Checking RAM and swap memory..."
echo "Total RAM: ${TOTAL_RAM}MB, Swap: ${SWAP_TOTAL}MB, Minimum required: ${MIN_SWAP_MB}MB"

if [[ "$TOTAL_RAM" -lt 4000 ]]; then
    echo "Insufficient RAM (${TOTAL_RAM}MB < 4000MB)."
    
    if [[ "$SWAP_TOTAL" -lt "$MIN_SWAP_MB" ]]; then
        echo "Insufficient swap space (${SWAP_TOTAL}MB < ${MIN_SWAP_MB}MB)."
        NEEDED_SWAP=$((MIN_SWAP_MB - SWAP_TOTAL))
        echo "Need to create or replace swap file with ${NEEDED_SWAP}MB."

        # Check if there is enough disk space for the swap
        if [[ "$DISK_SPACE" -lt "$NEEDED_SWAP" ]]; then
            echo "Error: Insufficient disk space (${DISK_SPACE}MB available, ${NEEDED_SWAP}MB required)."
            
            # If RAM >= 1GB, continue with a warning
            if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                echo "Warning: Not enough disk space to create swap, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail!"
            else
                # If RAM < 1GB, stop
                echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                echo "Please use a server with more resources (minimum 1GB RAM or 4GB disk space for swap)."
                exit 1
            fi
        else
            # Disk space is sufficient, proceed with swap creation
            if [[ -f "$SWAP_FILE" ]]; then
                # Check file size
                FILE_SIZE=$(stat -c %s "$SWAP_FILE" 2>/dev/null) || echo 0)
                echo "Existing swap file found at ${SWAP_FILE} with size ${FILE_SIZE} bytes."
                # Check if the file is an active swap
                if sudo swapon --show | grep -q "$SWAP_FILE"; then
                    sudo swapoff "$SWAP_FILE" 2>&1 | tee swapoff_error.log
                    if [[ $? -ne 0 ]]; then
                        echo "Error: Failed to disable existing swap. Details:"
                        cat swapoff_error.log
                        sudo rm -f swapoff_error.log
                        echo "Forcing deletion of swap file..."
                        # Remove immutable attributes if present
                        sudo chattr -i "$SWAP_FILE" 2>/dev/null
                        sudo rm -f "$SWAP_FILE" 2>&1 | tee rm_error.log
                        if [[ $? -ne 0 ]]; then
                            echo "Error: Failed to force delete swap file at ${SWAP_FILE}. Details:"
                            cat rm_error.log
                            sudo rm -f rm_error.log
                            exit 1
                        fi
                        sudo rm -f rm_error.log
                    else
                        sudo rm -f swapoff_error.log
                        # Remove immutable attributes if present
                        sudo chattr -i "$SWAP_FILE" 2>/dev/null
                        sudo rm -f "$SWAP_FILE" 2>&1 | tee rm_error.log
                        if [[ $? -ne 0 ]]; then
                            echo "Error: Failed to delete swap file at ${SWAP_FILE}. Details:"
                            cat rm_error.log
                            sudo rm -f rm_error.log
                            exit 1
                        fi
                        sudo rm -f rm_error.log
                    fi
                else
                    echo "File exists but is not an active swap. Forcing deletion..."
                    # Remove immutable attributes if present
                    sudo chattr -i "$SWAP_FILE" 2>/dev/null
                    sudo rm -f "$SWAP_FILE" 2>&1 | tee rm_error.log
                    if [[ $? -ne 0 ]]; then
                        echo "Error: Failed to force delete swap file at ${SWAP_FILE}. Details:"
                        cat rm_error.log
                        sudo rm -f rm_error.log
                        exit 1
                    fi
                    sudo rm -f rm_error.log
                fi
            fi

            # Re-check disk space after deletion
            DISK_SPACE=$(df -m / | awk 'NR>1 {print $4}') 2>/dev/null)
            if [[ "$DISK_SPACE" -lt "$NEEDED_SWAP" ]]; then
                echo "Error: Insufficient disk space after deletion (${DISK_SPACE}MB available, ${NEEDED_SWAP}MB required)."
                if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                    echo "Warning: Not enough disk space to create swap, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail."
                else
                    echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                    echo "Please use a server with more resources (e.g., minimum 1GB RAM or 4GB disk space for swap)."
                    exit 1
                fi
            fi

            # Create new swap file using dd
            echo "Creating new swap file of ${NEEDED_SWAPP}MB at ${SWAP_FILE}..."
            sudo dd if=/dev/zero of="$SWAP_FILE" bs=512 count=$((NEEDED_SWAP * 1024)) 2>&1 | tee dd_error.log
            if [[ $? -ne 0 || ! -f "$SWAP_FILE" || $(stat -c %s "$SWAP_FILE" 2>/dev/null) -lt $((NEEDED_SWAP * 1024 * 1024)) ]]; then
                echo "Error: Failed to create or verify swap file at ${SWAP_FILE}. Details:"
                cat dd_error.log
                sudo rm -f -f error.log
                # If RAM >= 1GB, continue with a warning
                if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                    echo "Warning: Failed to create swap file, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail."
                else
                    # If RAM < 1GB, stop
                    echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                    echo "Please use a server with more resources (e.g., minimum 1GB RAM or 4GB disk space for swap)."
                    exit 1
                fi
            else
                sudo rm -f dd_error.log
                # Continue with swap configuration
                sudo chmod 600 "$SWAP_FILE" >/dev/null 2>&1
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to set swap file permissions."
                    exit 1
                fi
                sudo mkswap "$SWAP_FILE" >/dev/null 2>&1
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to format swap file."
                    exit  fi
                sudo swapon "$SWAP_FILE" >/dev/null 2>&1
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to enable swap file."
                    exit 1
                fi
                CREATED_SWAP=true
                echo "New swap file created and enabled successfully."

                # Make swap persistent
                echo "Adding swap file to /etc/fstab for persistence..."
                echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
                if [[ $? -ne 0 ]]; then
                    echo "Error: Unable to add swap file to /etc/fstab."
                    exit 1
                fi
                echo "Swap file added to /etc/fstab for persistence."
            fi
        fi
    else
        echo "Swap space is sufficient (${SWAP_TOTAL}MB >= ${MIN_SWAPP}MB). No changes needed."
    fi
fi
else
    echo "RAM is sufficient (${TOTAL_RAM}MB >= ${MIN_swap}MB). No swap adjustments needed."
fi
