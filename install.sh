#!/usr/bin/env bash

# Exit on error
set -e

# Authenticate as sudo immediately
sudo -v

BASHRC="$(dirname "$0")/dots/bashrc"
NIX_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add NIX_DIR to PATH in bashrc if not already present
grep -q "export NIX_DIR=\"$NIX_DIR\"" "$BASHRC" || \
    echo "export NIX_DIR=\"$NIX_DIR\"" >> "$BASHRC"

# Enable alias expansion
eval "$(grep '^alias ' "$BASHRC")"
shopt -s expand_aliases
source "$BASHRC"


# Ask for the backup folder path
read -p "Enter the path to your gpg-backup folder: " BACKUP_DIR

# 1. Basic Folder Validation
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Directory $BACKUP_DIR not found."
    exit 1
fi

echo "--- Starting GPG Restoration ---"

# 2. Import Private/Public Keys
if [ -f "$BACKUP_DIR/my_private_keys.asc" ]; then
    echo "Importing Secret Keys..."
    gpg --import "$BACKUP_DIR/my_private_keys.asc"
else
    echo "Warning: my_private_keys.asc not found. Skipping key import."
fi

# 3. Import Owner Trust
if [ -f "$BACKUP_DIR/ownertrust.txt" ]; then
    echo "Importing Owner Trust..."
    gpg --import-ownertrust "$BACKUP_DIR/ownertrust.txt"
else
    echo "Warning: ownertrust.txt not found."
fi

# 4. Handle Configuration Files
echo "Configuring ~/.gnupg directory..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Copy config files if they exist in the backup
for f in sshcontrol gpg-agent.conf gpg.conf common.conf; do
    if [ -f "$BACKUP_DIR/$f" ]; then
        cp "$BACKUP_DIR/$f" ~/.gnupg/
        chmod 600 ~/.gnupg/"$f"
        echo "Restored: $f"
    fi
done

# 5. NixOS Specific Restart
echo "Restarting GPG Agent (systemd)..."
systemctl --user restart gpg-agent

# 6. Update TTY and Refresh Socket
echo "Updating TTY and checking SSH connection..."
gpg-connect-agent updatestartuptty /bye

# 7. Verification
echo "--- Verification ---"
echo "Available SSH Keys in GPG:"
ssh-add -l

echo ""
echo "GPG Restoration Complete!"
echo "If git fetch fails, remember to check if your SSH_AUTH_SOCK is exported in your shell config."

# Call update-all
update-all
