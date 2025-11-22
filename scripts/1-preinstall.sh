#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
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

# bios setup function
biossetup() {

# mkinitcpio
sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

# generate
mkinitcpio -P

# installing grub
installpackage grub

# Disable submenu's good for multiple kernels
sed -i 's/^#GRUB_DISABLE_SUBMENU=/GRUB_DISABLE_SUBMENU=/' /etc/default/grub

sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub

grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
}

# efi setup function
efisetup() {

# mkinitcpio setup
sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

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
fi

# installing boot loader
bootctl install

cat > /efi/loader/loader.conf <<'EOF'
default arch-linux-lts.efi
timeout 5
console-mode auto
editor no
EOF

systemctl enable systemd-boot-update.service
echo "root=/dev/mapper/archvolume-root rw" > /etc/kernel/cmdline

clear

echo -ne "
-------------------------------------------------------------------------
    _             _     _           _        _ _
   / \   _ __ ___| |__ (_)_ __  ___| |_ __ _| | | ___ _ __
  / _ \ | '__/ __| '_ \| | '_ \/ __| __/ _  | | |/ _ \ '__|
 / ___ \| | | (__| | | | | | | \__ \ || (_| | | |  __/ |
/_/   \_\_|  \___|_| |_|_|_| |_|___/\__\__,_|_|_|\___|_|
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

-------------------------------------------------------------------------
                  Creating user & Password setup
-------------------------------------------------------------------------
"

if [[ $(whoami) = "root" ]]; then
    # use chpasswd to enter $USERNAME:$password
    echo "$(whoami):${password}" | chpasswd
    echo "$(whoami) password set"
fi

# Creating username
useradd -m -G wheel -s /bin/bash ${username}

echo "${username}:${password}" | chpasswd
echo "$username password set"

# Adding user to wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


echo -ne "
-------------------------------------------------------------------------
                            Time setup
-------------------------------------------------------------------------
"
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
echo "Timezone: ${timezone}"

echo -ne "
-------------------------------------------------------------------------
                        Localization
-------------------------------------------------------------------------
"

#sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i "s/^#${localization}/${localization}/" /etc/locale.gen

locale-gen

language=$(echo "$localization" | awk '{print $1}')

echo "LANG=$language" > /etc/locale.conf


# installing tty font package
pacman -S terminus-font --noconfirm --needed
echo "KEYMAP=${key_layout}" > /etc/vconsole.conf && echo "FONT=ter-132b" >> /etc/vconsole.conf


echo -ne "
-------------------------------------------------------------------------
                        Network configuration
-------------------------------------------------------------------------
"

# setting up host name
echo "${name_of_machine}" >> /etc/hostname
systemctl enable NetworkManager
echo "Hostname: ${name_of_machine}"


echo -ne "
------------------------------------------------------------------------------------------------
 Configure mkinitcpio & Configure the kernel cmdline & .preset file & Installing the bootloader
------------------------------------------------------------------------------------------------
"
if [[ $platform == "EFI" ]]; then
    # efi setup funtion (function above of the page)
    efisetup

elif [[ $platform == "BIOS" ]]; then
    # Bios setup funtion (function above of the page)
    biossetup
fi

echo "Finished 1-preinstall.sh"
