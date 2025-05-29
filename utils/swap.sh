#!/bin/bash
#################################################################################
# Author: Vaudois (original), modified by Grok
#
# Program:
#   Check or create swap for this installation, avoiding unnecessary swapoff
#################################################################################

function make_swap 
{
    # Check and manage swap for compilation
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
    MIN_SWAP_MB=4096  # Minimum swap required (4GB)
    SWAP_FILE="/swapfile_yiimp"
    CREATED_SWAP=false
    
    echo "Checking RAM and swap memory..."
    echo "Total RAM: ${TOTAL_RAM}MB, Swap: ${SWAP_TOTAL}MB, Minimum required: ${MIN_SWAP_MB}MB"
    
    if [[ "$TOTAL_RAM" -lt 4000 ]]; then
        echo "Insufficient RAM (${TOTAL_RAM}MB < 4000MB)."
        
        if [[ "$SWAP_TOTAL" -ge "$MIN_SWAP_MB" ]]; then
            echo "Swap space is sufficient (${SWAP_TOTAL}MB >= ${MIN_SWAP_MB}MB). No changes needed."
            return 0
        fi

        echo "Insufficient swap space (${SWAP_TOTAL}MB < ${MIN_SWAP_MB}MB)."
        
        # Check available disk space (in MB) in the root directory
        DISK_SPACE=$(df -m / | awk 'NR==2 {print $4}' 2>/dev/null || echo 0)
        
        # Calculate needed swap
        NEEDED_SWAP=$((MIN_SWAP_MB - SWAP_TOTAL))
        echo "Need to create or replace swap file with ${NEEDED_SWAP}MB."

        # Check if there is enough disk space for the swap
        if [[ "$DISK_SPACE" -lt "$NEEDED_SWAP" ]]; then
            echo "Error: Insufficient disk space (${DISK_SPACE}MB available, ${NEEDED_SWAP}MB required)."
            if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                echo "Warning: Not enough disk space to create swap, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail!"
            else
                echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                echo "Please use a server with more resources (minimum 1GB RAM or 4GB disk space for swap)."
                exit 1
            fi
        else
            # Disable all active swaps only if we need to modify the swap
            echo "Disabling all active swap spaces..."
            sudo swapoff -a 2>/dev/null
            if [[ $? -ne 0 ]]; then
                echo "Warning: Failed to disable swap spaces. Attempting to proceed..."
            fi

            # Check if swap file already exists
            if [[ -f "$SWAP_FILE" ]]; then
                # Check file size
                FILE_SIZE=$(stat -c %s "$SWAP_FILE" 2>/dev/null || echo 0)
                echo "Existing swap file found at ${SWAP_FILE} with size ${FILE_SIZE} bytes."
                # Ensure the file is not an active swap
                if sudo swapon --show | grep -q "$SWAP_FILE"; then
                    sudo swapoff "$SWAP_FILE" 2>&1 | tee swapoff_error.log
                    if [[ $? -ne 0 ]]; then
                        echo "Error: Failed to disable existing swap. Details:"
                        cat swapoff_error.log
                        sudo rm -f swapoff_error.log
                        echo "Forcing deletion of swap file..."
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
            DISK_SPACE=$(df -m / | awk 'NR==2 {print $4}' 2>/dev/null || echo 0)
            if [[ "$DISK_SPACE" -lt "$NEEDED_SWAP" ]]; then
                echo "Error: Insufficient disk space after deletion (${DISK_SPACE}MB available, ${NEEDED_SWAP}MB required)."
                if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                    echo "Warning: Not enough disk space to create swap, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail!"
                else
                    echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                    echo "Please use a server with more resources (minimum 1GB RAM or 4GB disk space for swap)."
                    exit 1
                fi
            fi
    
            # Create new swap file using fallocate, fall back to dd if fallocate is not supported
            echo "Creating new swap file of ${NEEDED_SWAP}MB at ${SWAP_FILE}..."
            if ! command -v fallocate >/dev/null || ! sudo fallocate -l 1M /test_fallocate 2>/dev/null; then
                echo "fallocate not supported, falling back to dd..."
                sudo rm -f /test_fallocate
                sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$NEEDED_SWAP" 2>&1 | tee dd_error.log
                if [[ $? -ne 0 || ! -f "$SWAP_FILE" || $(stat -c %s "$SWAP_FILE" 2>/dev/null) -lt $((NEEDED_SWAP * 1024 * 1024)) ]]; then
                    echo "Error: Failed to create or verify swap file at ${SWAP_FILE}. Details:"
                    cat dd_error.log
                    sudo rm -f dd_error.log
                    if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                        echo "Warning: Failed to create swap file, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail!"
                    else
                        echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                        echo "Please use a server with more resources (minimum 1GB RAM or 4GB disk space for swap)."
                        exit 1
                    fi
                else
                    sudo rm -f dd_error.log
                fi
            else
                sudo rm -f /test_fallocate
                sudo fallocate -l "${NEEDED_SWAP}M" "$SWAP_FILE" 2>&1 | tee fallocate_error.log
                if [[ $? -ne 0 || ! -f "$SWAP_FILE" || $(stat -c %s "$SWAP_FILE" 2>/dev/null) -lt $((NEEDED_SWAP * 1024 * 1024)) ]]; then
                    echo "Error: Failed to create or verify swap file at ${SWAP_FILE}. Details:"
                    cat fallocate_error.log
                    sudo rm -f fallocate_error.log
                    if [[ "$TOTAL_RAM" -ge 1000 ]]; then
                        echo "Warning: Failed to create swap file, but RAM >= 1GB (${TOTAL_RAM}MB). Installation may fail!"
                    else
                        echo "Error: Insufficient RAM (${TOTAL_RAM}MB) < 1GB and unable to create swap. Installation impossible."
                        echo "Please use a server with more resources (minimum 1GB RAM or 4GB disk space for swap)."
                        exit 1
                    fi
                else
                    sudo rm -f fallocate_error.log
                fi
            fi
                
            # Continue with swap configuration
            sudo chmod 600 "$SWAP_FILE" >/dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to set swap file permissions."
                exit 1
            fi
            sudo mkswap "$SWAP_FILE" >/dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to format swap file."
                exit 1
            fi
            sudo swapon "$SWAP_FILE" >/dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to enable swap file."
                exit 1
            fi
            CREATED_SWAP=true
            echo "New swap file created and enabled successfully."
    
            # Make swap persistent
            echo "Adding swap file to /etc/fstab for persistence..."
            # Check if swap entry already exists in /etc/fstab to avoid duplicates
            if ! grep -q "$SWAP_FILE" /etc/fstab; then
                echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
                if [[ $? -ne 0 ]]; then
                    echo "Error: Unable to add swap file to /etc/fstab."
                    exit 1
                fi
                echo "Swap file added to /etc/fstab for persistence."
            else
                echo "Swap file already present in /etc/fstab, skipping addition."
            fi
        fi
    else
        echo "RAM is sufficient (${TOTAL_RAM}MB >= 4000MB). No swap adjustments needed."
    fi
}
