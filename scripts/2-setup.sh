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
                            ucode
-------------------------------------------------------------------------
"
cpu_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${cpu_type}; then
    echo "Installing Intel microcode"
    installpackage intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${cpu_type}; then
    echo "Installing AMD microcode"
    installpackage amd-ucode
    proc_ucode=amd-ucode.img
fi

clear

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
if lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo "AMD GPU detected..."
    installpackage vulkan-radeon mesa
elif lspci | grep 'VGA' | grep -E "Intel"; then
    echo "Intel GPU detected..."
    installpackage vulkan-intel mesa
else
    echo "No recognized GPU found"
fi

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
