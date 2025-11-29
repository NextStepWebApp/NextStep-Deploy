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
                        NextStep Web App Setup
-------------------------------------------------------------------------
"

installpackage php php-sqlite php-fpm apache python git
systemctl enable --now httpd.service

/srv/http
sudo chown -R http:http .

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

# Start services
systemctl enable --now php-fpm.service
systemctl restart httpd.service

# Enable Sqlite extention
sed -i 's/^;extension=sqlite3/extension=sqlite3/' /etc/php/php.ini

# Clone the NextStep repo from github

git clone https://github.com/NextStepWebApp/NextStep.git /srv/http




clear

echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
echo "Nog aan werken"
echo "Firewall opzet doen"
