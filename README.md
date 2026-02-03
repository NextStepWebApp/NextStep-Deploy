# NextStep Archinstaller

A bash script based on an existing Arch installer script, modified to suit the NextStep installation requirements.

Warning: It is not recommended at the moment to use this script for a permanent or long-running instance to host the alumni system. Please check the to-do list below for outstanding issues.

## Installation

### One-Line Install (Recommended)

```bash
bash <(curl -sL https://github.com/NextStepWebApp/NextStep-Deploy/raw/refs/heads/main/setup.sh)
```

This is the recommended installation method, especially for non-technical users.

### Manual Installation

For those who want more transparency and have technical experience, you can install manually via git:

1. Boot into the Arch Linux live ISO

2. Install git:
   ```bash
   pacman -Sy git
   ```

3. Clone this repository:
   ```bash
   git clone <repository-url>
   ```

4. Navigate to the directory and run the installer:
   ```bash
   cd Archinstaller
   bash archinstaller.sh
   ```

## About

This project, along with others in the NextStepWebApp repository, is being developed as a senior year high school final project.

The original script was created by the same developer who started NextStep, so this is essentially a fork of their own work. And of course, it's just a super cool flex as an Arch user to say that my school uses Arch btw...

## Why Arch Linux?

We chose to go with Arch and a custom script because we wanted full control over the system we provide to our users. Arch's rolling release model works great because it will update forever without ever needing a major upgrade, which would probably require someone with technical knowledge. This rolling release model will make it a forever living server, in a way, combined with nstep (https://github.com/NextStepWebApp/nstep) for managing the web app. nstep will probably also get a pacman wrapper in the future. 

Another advantage of Arch is that it gives us the opportunity to have the user type just one command - a single script that sets up everything. This would be different with other distributions where the user would have to go through a graphical installer and then run a separate script after installation to set up our alumni system.

## BIOS vs UEFI Configuration

The script currently has different behavior for BIOS and UEFI installations:

### BIOS Installations

For BIOS installations, the script sets up LVM even though it's not strictly necessary. This just adds more packages without much benefit. LVM is only really valuable for encrypted installations.

The reason BIOS installations don't support disk encryption is because after each reboot, the user would need to go to the server and manually type the password to unlock the disk. This is not practical, especially since Arch is a rolling release and restarts would be required periodically.

### UEFI Installations

UEFI systems support disk encryption with auto-unlock via TPM, which is very easy to set up. We are planning to provide more detailed instructions on how to set up TPM auto-unlock and secure boot for UEFI systems.

## Alternative Distributions

You could argue that if you have experience, you might want to use a different distribution. That should be made possible since nstep is planning to support multiple distributions. The NextStep Deploy script is just a script that handles OS installation plus nstep installation with some handy user commands. In a way, it is what the NextStep developers want to provide as the final product.

There's a chance we will officially support CachyOS Server in the future (currently still in development and unreleased). The CachyOS team has done wonderful work with their desktop version - they gave Arch steroids out of the box, in a way. That's what they're planning for the server release too, which is interesting. But only time will tell if we go that route. For now, NextStep-Deploy is the only way to use our NextStep alumni system.

## To-Do List

- Fix some setup for BIOS and UEFI things
- Clean up the code
- Add nstep setup to the deploy script
- Document the custom commands that are set up by the deploy script to make users' lives easier

## Contributing

Contributions are very welcome. Please make sure to communicate and open an issue before working on something to avoid duplicate efforts.

If you encounter any problems, please open an issue and you will be assisted.
