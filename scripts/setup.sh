#!/bin/bash
# This script only gets information from the user, this information will be stored and used in the other scripts

echo -ne "
-------------------------------------------------------------------------
                      Setting up keyboard layout
-------------------------------------------------------------------------
"

echo "Please select keyboard layout from this list"
echo ""

options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

for choice in ${options[@]}; do
    echo -n "$choice "
done

echo ""
echo ""
read -p "Enter your key boards layout: " key_layout

found_key=n

while true; do
    for choice in ${options[@]}; do
        if [[ $key_layout == $choice ]]; then
            found_key=y
            break
        fi
    done
    if [[ $found_key == y ]]; then
        echo ""
        echo "Your selected keyboard layout: ${key_layout}"
        break
    else
        echo "ERROR - enter a valid input"
        read -p "Enter your key boards layout: " key_layout
    fi
done

# load the keyboard layout
loadkeys ${key_layout}

# username
username="admin"

clear 

echo -ne "
-------------------------------------------------------------------------
                         Setting up Password
-------------------------------------------------------------------------
"

# Set a user password
while true; do
    read -s -p "Please enter a password: " password
    echo ""
    if (( ${#password} < 2 )); then
        echo "Password must be at least 2 characters"
        continue
    fi
    read -s -p "Confirm password: " password_confirm
    echo ""
    if [[ "$password" == "$password_confirm" ]]; then
        echo "Password setup success"
        break
    else
        echo "Passwords do not match. Try again."
    fi
done

# Set hostname

name_of_machine="nextstepserver"

clear

echo -ne "
-------------------------------------------------------------------------
                        Choose your timezone
-------------------------------------------------------------------------
"

# Get timezone from IP
timezone="$(curl --fail https://ipapi.co/timezone 2>/dev/null)"

if [[ -z "$timezone" ]]; then
    echo "Could not detect timezone automatically"
    timezone_detected=n
else
    echo "Detected timezone: $timezone"
    read -p "Is this your timezone? (y/n): " answer
    
    while true; do
        if [[ $answer == "y" || $answer == "Y" ]]; then
            timezone_detected=y
            break
        elif [[ $answer == "n" || $answer == "N" ]]; then
            timezone_detected=n
            break
        else
            read -p "Enter a valid input (y/n): " answer
        fi
    done
fi

if [[ $timezone_detected == "n" || -z "$timezone" ]]; then
    echo ""
    echo "Available regions:"
    ls /usr/share/zoneinfo/ | grep -v -E '^(posix|right)$' | column
    echo ""

    while true; do
        read -p "Enter your region (e.g., America, Europe, Asia): " region
        if [[ ${#region} -lt 2 ]]; then
            echo "Region name too short"
            continue
        fi
        if [[ -d "/usr/share/zoneinfo/$region" ]]; then
            break
        else
            echo "Invalid region. Please try again."
        fi
    done

    echo ""
    echo "Available cities/zones in $region:"
    ls "/usr/share/zoneinfo/$region" | column
    echo ""

    while true; do
        read -p "Enter your city/zone (e.g., New_York, London, Tokyo): " city
        if [[ -f "/usr/share/zoneinfo/$region/$city" ]]; then
            timezone="$region/$city"
            break
        else
            echo "Invalid city/zone. Please try again."
        fi
    done
    echo "Timezone selected: $timezone"
fi

# Checking Firmware
if [[ -f /sys/firmware/efi/fw_platform_size ]]; then
    EFI_SIZE=$(cat /sys/firmware/efi/fw_platform_size)
    platform=EFI
else
    platform=BIOS
fi

clear
echo -ne "
-------------------------------------------------------------------------
                        Formatting the disk
-------------------------------------------------------------------------
"
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

while true; do
    read -p "Enter disk name (e.g., sda, nvme0n1): " DISK_NAME
    DISK="/dev/$DISK_NAME"
    if [[ -b "$DISK" ]]; then
        echo "Selected disk: $DISK"
        break
    else
        echo "Invalid disk. Try again."
    fi
done

clear
echo -ne "
-------------------------------------------------------------------------
                        INSTALLATION CONFIRMATION
-------------------------------------------------------------------------
"
echo -ne "
Please review your installation configuration:

Firmware Type:        $platform
Target Disk:          $DISK
Hostname:             $name_of_machine
Timezone:             $timezone
Username:             $username
Password:             $(printf '%*s' ${#password} '' | tr ' ' '*')

"

echo "***********************************************************"
echo " WARNING: You are about to completely WIPE ${DISK}!"
echo " All data on this disk will be LOST forever."
echo "***********************************************************"
echo ""

while true; do
    read -p "Continue with installation? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        echo "Proceeding with installation..."
        break
    elif [[ $confirm == "n" || $confirm == "N" ]]; then
        echo "Installation cancelled."
        exit 0
    else
        echo "Enter a valid input (y/n)"
    fi
done

# Store variables for later use
cat > scripts/vars.sh << EOF
# Archinstaller configuration variables

# Disk & system information
DISK=$DISK
platform=$platform

# User & hostname creation
username=$username
password=$password
name_of_machine=$name_of_machine
timezone=$timezone
key_layout=$key_layout
EOF

echo "Configuration saved to scripts/vars.sh"
