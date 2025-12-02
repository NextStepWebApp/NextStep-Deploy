#!/bin/bash

# Sync script

if [[ $developer_deploy == "Yes" ]]; then 
cat > /opt/nextstepwebapp/sync-configs.sh << 'EOF'
#!/bin/bash
# NextStep Config Sync - Updates system configs from git repo

echo "Syncing configs from git to system..."
sudo cp /srv/http/NextStep/config/*.json /var/lib/nextstepwebapp/
sudo cp /srv/http/NextStep/config/nextstep_config.json /etc/nextstepwebapp/
sudo cp /srv/http/NextStep/data/import.py /opt/nextstepwebapp/
echo "Done! Configs synced."
EOF

chmod +x /opt/nextstepwebapp/sync-configs.sh
echo "Sync script created at /opt/nextstepwebapp/sync-configs.sh"

# Add alias to user's .bashrc
if ! grep -q "nextstep-sync" /home/admin/.bashrc; then
    echo "alias nextstep-sync='/opt/nextstepwebapp/sync-configs.sh'" >> ~/.bashrc
    echo "Alias added to .bashrc"
fi
fi

# Create post-login setup script
cat > /etc/profile.d/nextstep-setup.sh << 'EOF'
#!/bin/bash
SETUP_FLAG="/opt/nextstepwebapp/.initial_setup_complete"

if [ ! -f "$SETUP_FLAG" ]; then
    echo "Running first-time NextStep setup..."
    sudo systemctl enable --now cockpit.socket
    sudo systemctl enable --now ufw
    sudo ufw enable
    sudo ufw allow 9090 # cockpit
    sudo ufw allow 80 # normal web port 
    sudo ufw allow 22 # ssh
    sudo touch "$SETUP_FLAG"
    echo "✓ Setup complete! Cockpit and firewall enabled."
fi
EOF

chmod +x /etc/profile.d/nextstep-setup.sh
