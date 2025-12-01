#!/bin/bash

source /usr/local/share/Archinstaller/scripts/vars.sh

installpackage() {
    local pkgs="$@"
    while true; do
        if ! pacman -S --noconfirm --needed $pkgs; then
            echo "ERROR: Failed to install: $pkgs"
            echo "Retrying..."
        else
            echo "SUCCESS: Installed $pkgs"
            break
        fi
    done
}

clear

echo -ne "
-------------------------------------------------------------------------
                        pacman configuration
-------------------------------------------------------------------------
"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf

clear
echo -ne "
-------------------------------------------------------------------------
                         Installing Cockpit
-------------------------------------------------------------------------
"
installpackage cockpit

# Activate cockpit
#systemctl enable --now cockpit

echo "Finished 2-setup.sh"
