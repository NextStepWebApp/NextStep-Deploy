#!/bin/bash

# Function with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/scripts/vars.sh
source /usr/local/share/Archinstaller/scripts/config.sh

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

# BIOS setup function
biossetup() {
    # mkinitcpio
    sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    
    # installing grub
    installpackage grub

    # Disable submenu's good for multiple kernels
    sed -i 's/^#GRUB_DISABLE_SUBMENU=/GRUB_DISABLE_SUBMENU=/' /etc/default/grub
    sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub

    grub-install --target=i386-pc ${DISK}
    grub-mkconfig -o /boot/grub/grub.cfg
}

# EFI setup function
efisetup() {
    # mkinitcpio setup
    if [[ $disk_encrypt == "y" && $platform == "EFI" ]]; then
        sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf   
    else 
        sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    fi

    # .preset files
    # mkinitcpio preset file for the 'linux-lts' package
    cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default' 'fallback')

default_uki="/efi/EFI/Linux/arch-linux-lts.efi"

fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
EOF

    # installing boot loader
    bootctl install

    cat > /efi/loader/loader.conf <<'EOF'
default arch-linux-lts.efi
timeout 5
console-mode auto
editor no
EOF

    systemctl enable systemd-boot-update.service
    
    if [[ $disk_encrypt == "y" && $platform == "EFI" ]]; then 
        echo "rd.luks.name=${LUKS_UUID}=cryptlvm root=/dev/archvolume/root rw" > /etc/kernel/cmdline
    else 
        echo "root=/dev/mapper/archvolume-root rw" > /etc/kernel/cmdline
    fi
}

clear

echo -ne "
-------------------------------------------------------------------------
                  Creating user & Password setup
-------------------------------------------------------------------------
"

if [[ $(whoami) = "root" ]]; then
    # use chpasswd to enter root password
    echo "$(whoami):${password}" | chpasswd
    echo "$(whoami) password set"
fi

# Creating username
useradd -m -G wheel -s /bin/bash ${username}

echo "${username}:${password}" | chpasswd
echo "$username password set"

# Adding user to wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

clear

echo -ne "
-------------------------------------------------------------------------
                            Time setup
-------------------------------------------------------------------------
"
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
echo "Timezone: ${timezone}"

clear

echo -ne "
-------------------------------------------------------------------------
                              Localization
-------------------------------------------------------------------------
"

sed -i "s/^#${localization}/${localization}/" /etc/locale.gen

locale-gen

language=$(echo "$localization" | awk '{print $1}')

echo "LANG=$language" > /etc/locale.conf

clear

echo -ne "
-------------------------------------------------------------------------
                        Network configuration
-------------------------------------------------------------------------
"

# setting up host name
echo "${name_of_machine}" >> /etc/hostname
systemctl enable NetworkManager
echo "Hostname: ${name_of_machine}"

clear

echo -ne "
------------------------------------------------------------------------------------------------
 Configure mkinitcpio & Configure the kernel cmdline & .preset file & Installing the bootloader
------------------------------------------------------------------------------------------------
"

if [[ $platform == "EFI" ]]; then
    # efi setup function
    efisetup
elif [[ $platform == "BIOS" ]]; then
    # Bios setup function
    biossetup
else
    echo "ERROR: Unknown platform"
    exit 1
fi

# generate
mkinitcpio -p linux-lts

echo "Finished 1-preinstall.sh"
