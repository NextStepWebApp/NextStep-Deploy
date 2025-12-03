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
                        NextStep Web App Setup
-------------------------------------------------------------------------
"

# Activate cockpit
#systemctl enable cockpit
installpackage php php-sqlite php-fpm apache python git cockpit ufw
systemctl enable httpd.service


# Enable proxy modules
sed -i 's/^#LoadModule proxy_module/LoadModule proxy_module/' /etc/httpd/conf/httpd.conf
sed -i 's/^#LoadModule proxy_fcgi_module/LoadModule proxy_fcgi_module/' /etc/httpd/conf/httpd.conf

# Create php-fpm config
mkdir -p /etc/httpd/conf/extra
cat > /etc/httpd/conf/extra/php-fpm.conf << 'EOF'
DirectoryIndex index.php index.html
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost/"
</FilesMatch>
EOF

# Include config if not already there
if ! grep -q "Include conf/extra/php-fpm.conf" /etc/httpd/conf/httpd.conf; then
    echo "Include conf/extra/php-fpm.conf" >> /etc/httpd/conf/httpd.conf
fi

# change made for apache
grep -q "^ServerName" /etc/httpd/conf/httpd.conf || echo "ServerName localhost" | sudo tee -a /etc/httpd/conf/httpd.conf

# Start services
systemctl enable php-fpm.service
systemctl restart httpd.service

# Enable Sqlite extention
sed -i 's/^;extension=sqlite3/extension=sqlite3/' /etc/php/php.ini

# Clone the NextStep repo from github
git clone https://github.com/NextStepWebApp/NextStep.git /srv/http/NextStep

# Make the directorys where the files will go
mkdir /var/lib/nextstepwebapp
mkdir /opt/nextstepwebapp
mkdir /etc/nextstepwebapp

if [[ $developer_deploy == "Yes" ]]; then 
    # cp files to the places where they need to be. Use the nextstep-sync command to sync the files 
    mkdir -p /var/lib/nextstepwebapp /etc/nextstepwebapp /opt/nextstepwebapp
    
    cp /srv/http/NextStep/config/branding.json /var/lib/nextstepwebapp/
    cp /srv/http/NextStep/config/setup.json /var/lib/nextstepwebapp/
    cp /srv/http/NextStep/config/errors.json /var/lib/nextstepwebapp/
    cp /srv/http/NextStep/config/config.json /var/lib/nextstepwebapp/
    cp /srv/http/NextStep/config/nextstep_config.json /etc/nextstepwebapp/
    cp /srv/http/NextStep/data/import.py /opt/nextstepwebapp/
   
    chown -R admin:admin /srv/http/NextStep
else
    mv /srv/http/NextStep/config/nextstep_config.json /etc/nextstepwebapp #This file is only read by the webapp
    # The rest of the configs go to /var/lib
    mv /srv/http/NextStep/config/branding.json /var/lib/nextstepwebapp
    mv /srv/http/NextStep/config/config.json /var/lib/nextstepwebapp
    mv /srv/http/NextStep/config/errors.json /var/lib/nextstepwebapp
    mv /srv/http/NextStep/config/setup.json /var/lib/nextstepwebapp
    rm -rf /srv/http/NextStep/config # remove the config dir
    # Move the python file to /opt/nextstepwebapp
    mv /srv/http/NextStep/data/import.py /opt/nextstepwebapp
    rm -rf /srv/http/NextStep/data

    # Permissions application code
    chown -R root:root /srv/http/NextStep
    chmod -R 755 /srv/http/NextStep

fi
# /var/lib
chown -R http:http /var/lib/nextstepwebapp
chmod -R 775 /var/lib/nextstepwebapp

# /etc
chown -R root:root /etc/nextstepwebapp
chmod -R 755 /etc/nextstepwebapp/

# /opt
chown -R root:root /opt/nextstepwebapp
chmod -R 755 /opt/nextstepwebapp

clear

echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
# Firewall and openssh setup
systemctl enable sshd.service
systemctl enable ufw
# The rest of the Networking setup will be done post-setup
