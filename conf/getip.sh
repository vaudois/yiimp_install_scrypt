#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by vaudois for crypto use...
#####################################################

source /etc/functions.sh

echo
echo
echo -e "$CYAN => Setting our global variables : $COL_RESET"
echo

# Définir la variable DISTRO pour Ubuntu 20.04 (20) ou 22.04 (22)
if [ -z "${DISTRO:-}" ]; then
    DISTRO=$(lsb_release -r -s | cut -d '.' -f 1)
    if [[ "$DISTRO" != "20" && "$DISTRO" != "22" ]]; then
        echo -e "$RED Error: This script supports only Ubuntu 20.04 or 22.04. Detected version: $DISTRO.$COL_RESET"
        exit 1
    fi
fi

# If the machine is behind a NAT, inside a VM, etc., it may not know
# its IP address on the public network / the Internet. Ask the Internet
# and possibly confirm with user.
if [ -z "${PUBLIC_IP:-}" ]; then
    # Ask the Internet.
    GUESSED_IP=$(get_publicip_from_web_service 4)

    # On the first run, if we got an answer from the Internet then don't
    # ask the user.
    if [[ -z "${DEFAULT_PUBLIC_IP:-}" && ! -z "$GUESSED_IP" ]]; then
        PUBLIC_IP=$GUESSED_IP

    # On later runs, if the previous value matches the guessed value then
    # don't ask the user either.
    elif [ "${DEFAULT_PUBLIC_IP:-}" == "$GUESSED_IP" ]; then
        PUBLIC_IP=$GUESSED_IP
    fi

    if [ -z "${PUBLIC_IP:-}" ]; then
        input_box "Public IP Address" \
            "Enter the public IP address of this machine, as given to you by your ISP.
            \n\nPublic IP address:" \
            "$DEFAULT_PUBLIC_IP" \
            PUBLIC_IP

        if [ -z "$PUBLIC_IP" ]; then
            # user hit ESC/cancel
            exit
        fi
    fi
fi

# Same for IPv6. But it's optional. Also, if it looks like the system
# doesn't have an IPv6, don't ask for one.
if [ -z "${PUBLIC_IPV6:-}" ]; then
    # Ask the Internet.
    GUESSED_IP=$(get_publicip_from_web_service 6)
    MATCHED=0
    if [[ -z "${DEFAULT_PUBLIC_IPV6:-}" && ! -z "$GUESSED_IP" ]]; then
        PUBLIC_IPV6=$GUESSED_IP
    elif [[ "${DEFAULT_PUBLIC_IPV6:-}" == "$GUESSED_IP" ]]; then
        # No IPv6 entered and machine seems to have none, or what
        # the user entered matches what the Internet tells us.
        PUBLIC_IPV6=$GUESSED_IP
        MATCHED=1
    elif [[ -z "${DEFAULT_PUBLIC_IPV6:-}" ]]; then
        DEFAULT_PUBLIC_IP=$(get_default_privateip 6)
    fi

    if [[ -z "${PUBLIC_IPV6:-}" && $MATCHED == 0 ]]; then
        input_box "IPv6 Address (Optional)" \
            "Enter the public IPv6 address of this machine, as given to you by your ISP.
            \n\nLeave blank if the machine does not have an IPv6 address.
            \n\nPublic IPv6 address:" \
            ${DEFAULT_PUBLIC_IPV6:-} \
            PUBLIC_IPV6

        if [ ! $PUBLIC_IPV6_EXITCODE ]; then
            # user hit ESC/cancel
            exit
        fi
    fi
fi

# Automatic configuration, e.g. as used in our Vagrant configuration.
if [ "$PUBLIC_IP" = "auto" ]; then
    # Use a public API to get our public IP address, or fall back to local network configuration.
    PUBLIC_IP=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi
if [ "$PUBLIC_IPV6" = "auto" ]; then
    # Use a public API to get our public IPv6 address, or fall back to local network configuration.
    PUBLIC_IPV6=$(get_publicip_from_web_service 6 || get_default_privateip 6)
fi
if [ -z "${PRIVATE_IP:-}" ]; then
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
fi

echo -e "$GREEN Done...$COL_RESET"
