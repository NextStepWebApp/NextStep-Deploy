#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
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
                        Desktop customizations
-------------------------------------------------------------------------
"

echo "hier moet de specifieke opzet gaan komen voor nextstep"

clear

echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
echo "Nog aan werken"
echo "Firewall opzet doen"
