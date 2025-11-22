#!/bin/bash
# This script only gets information from the user, this information will be stored and used in the other scripts

echo -ne "
-------------------------------------------------------------------------
                Setting up username and password
-------------------------------------------------------------------------
"

echo "Please select key board layout from this list"
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

# Set a user password
while true; do
    read -s -p "Please enter user password: " password
    echo ""
    if (( ${#password} < 2 )); then
        continue
    fi
    read -s -p "Confirm password: " password_confirm
    if [[ "$password" == "$password_confirm" ]]; then
        echo ""
        echo "Password setup success"
        break
    else
        echo ""
        echo "User passwords do not match. Try again."
    fi
done

echo -ne "
-------------------------------------------------------------------------
                        Chose your timezone
-------------------------------------------------------------------------
"

# I know, a url !!!! Oh no!!! 
# Chill out this is a api to get yout timezone based of you ip
timezone="$(curl --fail https://ipapi.co/timezone)"

read -p "Is this your timezone? ${timezone} (y/n) " anwser
while true; do
    if [[ $anwser == "y" || $anwser == "Y" ]]; then
        break
    elif [[ $anwser == "n" || $anwser == "N" ]]; then
        break
    else
        echo "Enter a valid input"
    fi
done

if [[ $anwser == "n" || $anwser == "N" ]]; then

echo "Available regions:"
ls /usr/share/zoneinfo/ | tr '\n' ' ' | sort
echo ""

    while true; do
        read -p "Enter your region (e.g., America, Europe, Asia): " region
        echo ""
        if [[ $region < 2 ]]; then
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
    ls "/usr/share/zoneinfo/$region" | tr '\n' ' ' | sort
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
    read -p "Enter disk name (e.g., sda): " DISK_NAME
    DISK="/dev/$DISK_NAME"
    if [[ -b "$DISK" ]]; then
        break
    else
        echo "Invalid disk. Try again."
    fi
done
clear
echo -ne "
-------------------------------------------------------------------------
                        INSTALLATION CONFORMATION
-------------------------------------------------------------------------
"
sleep 1
echo -ne "
Please review your installation configuration:

Firmware Type:        $platform
Target Disk:          $DISK
Hostname:             $name_of_machine
Timezone:             $timezone
Username:             $username
Password:        $(printf '%*s' ${#password} '' | tr ' ' '*')


# end confirmation nex the disk wipe
echo "***********************************************************"
echo " WARNING: You are about to completely WIPE ${DISK}!"
echo " All data on this disk will be LOST forever."
echo "***********************************************************"
while true; do
    read -p "Continue (y/n) " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    elif [[ $confirm == "n" || $confirm == "N" ]]; then
        exit 0
    else
        echo "Enter a valid input"
    fi
done

# Store variables for later use

cat > scripts/vars.sh << EOF
# Archinstaller configuration variables

# Disk & system information
DISK=$DISK
platform=$platform
partition1=$partition1

# User & hostname creation
username=$username
password=$password
name_of_machine=$name_of_machine
timezone=$timezone
key_layout=$key_layout
EOF

# moet in 0 gaan
