#!/bin/bash

source scripts/vars.sh

installcleanup() {
    echo "Cleaning up and cancelling installation..."
    # Unmount all mounted filesystems
    umount -R /mnt 2>/dev/null
    # Deactivate swap
    swapoff /dev/mapper/archvolume-swap 2>/dev/null
    # Remove LVM volumes
    lvremove -f archvolume/swap 2>/dev/null
    lvremove -f archvolume/root 2>/dev/null
    lvremove -f archvolume/home 2>/dev/null
    # Remove volume group
    vgremove -f archvolume 2>/dev/null
    # Remove physical volume
    pvremove ${LVM_DEVICE} 2>/dev/null

    clear
    echo "========================================="
    echo "     Installation Cancelled"
    echo "========================================="
    echo "Disk has been cleaned up."
    echo "You can safely rerun the script."
    sleep 2
    exit 0
}

calculatelvm() {
    # Calculating sizes for lvm
    RAM_GB=$(free -m | awk '/^Mem:/ {printf "%.0f", $2/1024}')
    DISK_SIZE_RAW=$(lsblk -d -n -o SIZE $DISK)
    DISK_SIZE=$(echo $DISK_SIZE_RAW | sed 's/G//' | awk '{printf "%.0f", $1}')

    if [[ $DISK_SIZE -lt 40 ]]; then
        SWAP_SIZE=2
    else
        SWAP_SIZE=4
    fi
    ROOT_SIZE=$(((DISK_SIZE - SWAP_SIZE) * 40 / 100))
    echo "Swap size: ${SWAP_SIZE}G"
    echo "Root size: ${ROOT_SIZE}G"
}

set_partition_names() {
    # Wait for partition table to be recognized
    sleep 2
    partprobe ${DISK}
    sleep 1
    
    # Get partition names dynamically based on disk type
    if [[ ${DISK} =~ "nvme" ]]; then
        # NVMe drives use p1, p2, p3 format
        partition1="${DISK}p1"
        partition2="${DISK}p2"
        partition3="${DISK}p3"
    else
        # SATA/SCSI drives use 1, 2, 3 format
        partition1="${DISK}1"
        partition2="${DISK}2"
        partition3="${DISK}3"
    fi
    
    # Set LVM device based on platform
    if [[ $platform == "BIOS" ]]; then
        LVM_DEVICE="${partition3}"
    else
        LVM_DEVICE="${partition2}"
    fi
    
    echo "Partition 1: ${partition1}"
    echo "Partition 2: ${partition2}"
    if [[ $platform == "BIOS" ]]; then
        echo "Partition 3: ${partition3}"
    fi
    echo "LVM Device: ${LVM_DEVICE}"
}

setup_lvm() {
    echo "Setting up LVM..."
    # Create LVM setup
    pvcreate ${LVM_DEVICE}
    vgcreate archvolume ${LVM_DEVICE}
    lvcreate -L ${SWAP_SIZE}G -n swap archvolume
    lvcreate -L ${ROOT_SIZE}G -n root archvolume
    lvcreate -l 100%FREE -n home archvolume
    echo "LVM setup complete"
}

create_filesystems() {
    echo -ne "
-------------------------------------------------------------------------
                    Creating filesystems
-------------------------------------------------------------------------
"
    # Create filesystems
    mkfs.ext4 /dev/mapper/archvolume-root
    mkfs.ext4 /dev/mapper/archvolume-home
    mkswap /dev/mapper/archvolume-swap
     
    # Reduce home partition by 256M to leave some free space
    lvreduce -L -256M --resizefs archvolume/home
    echo "Filesystems created successfully"
}

mount_common_filesystems() {
    echo "Mounting filesystems..."
    # Mount the filesystems
    mount /dev/mapper/archvolume-root /mnt
    mkdir -p /mnt/home
    mount /dev/mapper/archvolume-home /mnt/home
    swapon /dev/mapper/archvolume-swap
    echo "Filesystems mounted"
}

# Function that formats the disk for an EFI firmware system
efisetup() {
    echo "Starting EFI setup..."
    calculatelvm
    set_partition_names
    setup_lvm
    create_filesystems
    mount_common_filesystems

    # Setup EFI partition
    echo "Setting up EFI partition..."
    mkfs.fat -F32 ${partition1}
    mkdir -p /mnt/efi
    mount ${partition1} /mnt/efi
    echo "EFI setup complete"
}

# Function that formats the disk for a BIOS firmware system
biossetup() {
    echo "Starting BIOS setup..."
    calculatelvm
    set_partition_names
    setup_lvm
    create_filesystems
    mount_common_filesystems

    # Setup BIOS boot partition
    echo "Setting up boot partition..."
    mkfs.fat -F32 ${partition2}
    mkdir -p /mnt/boot
    mount ${partition2} /mnt/boot
    echo "BIOS setup complete"
}

echo -ne "
-------------------------------------------------------------------------
                    Partitioning the disk
-------------------------------------------------------------------------
"

# Getting rid of everything
umount -A --recursive /mnt 2>/dev/null

# Wipe disk signatures
wipefs -af ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

# Create partitions based on platform
if [[ $platform == "EFI" ]]; then
    echo "Creating EFI partition layout..."
    sgdisk -n 1::+3G --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
    sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
    partprobe ${DISK}
    sleep 2
    efisetup
elif [[ $platform == "BIOS" ]]; then
    echo "Creating BIOS partition layout..."
    sgdisk -n 1::+2M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
    sgdisk -n 2::+1G --typecode=2:8300 --change-name=2:'BOOT' ${DISK}
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
    sgdisk -A 1:set:2 ${DISK}
    partprobe ${DISK}
    sleep 2
    biossetup
else
    echo "ERROR: Unknown platform, exiting..."
    exit 1
fi

echo -ne "
-------------------------------------------------------------------------
                    Partition layout complete
-------------------------------------------------------------------------
"

# Show final partition layout
lsblk ${DISK}
echo ""

# Confirmation step - allow user to cancel after seeing the result
while true; do
    read -p "Does the partition layout look correct? Continue (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo "Continuing with installation..."
        break
    elif [[ $answer == "n" || $answer == "N" ]]; then
        installcleanup
    else
        echo "Please enter 'y' or 'n'"
    fi
done

# Copy installation scripts to the new system
echo "Copying installation scripts..."
mkdir -p /mnt/usr/local/share/Archinstaller
cp -r "$SCRIPT_DIR"/* /mnt/usr/local/share/Archinstaller/
chmod +x /mnt/usr/local/share/Archinstaller/scripts/*

echo -ne "
-------------------------------------------------------------------------
                    Updating the system clock
-------------------------------------------------------------------------
"
timedatectl set-ntp true
timedatectl status

echo -ne "
-------------------------------------------------------------------------
                    Selecting the mirrors
-------------------------------------------------------------------------
"
echo "Updating mirrors with reflector..."
if ! reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
    echo "Warning: Reflector failed, using existing mirrors"
    echo "You may want to manually update /etc/pacman.d/mirrorlist later"
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing essential packages
-------------------------------------------------------------------------
"

packages="base base-devel bash linux-firmware linux-lts lvm2 networkmanager vim man-db man-pages texinfo"

# Add EFI boot manager if needed
if [[ $platform == "EFI" ]]; then
    packages+=" efibootmgr"
fi

# Install packages with retry logic
attempt=1
max_attempts=3
while true; do
    echo "Installation attempt ${attempt}/${max_attempts}..."
    if pacstrap -K /mnt --noconfirm --needed ${packages}; then
        echo "Package installation successful"
        break
    else
        echo "ERROR: Package installation failed"
        if [[ $attempt -ge $max_attempts ]]; then
            echo "Maximum attempts reached. Installation failed."
            installcleanup
        fi
        echo "Retrying in 5 seconds..."
        sleep 5
        ((attempt++))
    fi
done

echo -ne "
-------------------------------------------------------------------------
                    Configuring the system
-------------------------------------------------------------------------
"

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Fix mount options for boot partitions
if [[ $platform == "EFI" ]]; then
    echo "Fixing EFI mount boot options in fstab..."
    sed -i '/\/efi/ s/fmask=[0-9]\{4\}/fmask=0137/; s/dmask=[0-9]\{4\}/dmask=0027/' /mnt/etc/fstab
elif [[ $platform == "BIOS" ]]; then
    echo "Fixing BIOS mount boot options in fstab..."
    sed -i '/\/boot/ s/fmask=[0-9]\{4\}/fmask=0137/; s/dmask=[0-9]\{4\}/dmask=0027/' /mnt/etc/fstab
fi

# Display the generated fstab for verification
echo ""
echo "Generated fstab:"
cat /mnt/etc/fstab
echo ""

echo "Finished 0-preinstall.sh"
