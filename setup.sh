#!/bin/bash
curl -sL https://github.com/NextStepWebApp/NextStep-Deploy/archive/refs/heads/main.tar.gz -o main.tar.gz
tar -xzf main.tar.gz
cd NextStep-Deploy-main
bash archinstaller.sh
