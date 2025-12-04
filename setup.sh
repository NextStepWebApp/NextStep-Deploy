#!/bin/bash
curl -sL https://github.com/NextStepWebApp/NextStep-Deploy/archive/refs/heads/main.zip -o main.zip
unzip main.zip
cd NextStep-Deploy-main
bash archinstaller.sh
