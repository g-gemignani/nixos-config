#!/usr/bin/env bash

# Exit on error and undefined variables
set -euo pipefail

# Authenticate as sudo immediately
sudo -v

# Ask for the backup folder path
read -r -p "Enter the path to your gpg-backup folder: " BACKUP_DIR

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
install -d -m 700 "$HOME/.gnupg"

# Copy config files if they exist in the backup
for f in sshcontrol gpg-agent.conf gpg.conf common.conf; do
    if [ -f "$BACKUP_DIR/$f" ]; then
        cp "$BACKUP_DIR/$f" "$HOME/.gnupg/"
        chmod 600 "$HOME/.gnupg/$f"
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
if ! ssh-add -l; then
    echo "No SSH identities are currently loaded in the agent."
fi

echo ""
echo "GPG Restoration Complete!"
echo "If git fetch fails, remember to check if your SSH_AUTH_SOCK is exported in your shell config."

# 8. First system build
# The system is built straight from this repo. Nothing is copied to /etc/nixos.
NIX_DIR="${NIX_DIR:-$HOME/nixos-config}"

echo ""
echo "--- NixOS rebuild ---"

if [ ! -f "$NIX_DIR/flake.nix" ]; then
    echo "No flake.nix under $NIX_DIR."
    echo "Clone the config there, then run:"
    echo "  sudo nixos-rebuild switch --flake \"$NIX_DIR#<host>\""
    exit 0
fi

# A flake build only reads git-tracked files, so a fresh clone is required.
if ! git -C "$NIX_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Warning: $NIX_DIR is not a git repository."
    echo "A flake build only reads git-tracked files, so this will not work."
    echo "Clone the config with git instead of copying it."
    exit 1
fi

# Pick the config that matches this host, or the only one the flake defines.
HOST_NAME="$(hostname)"
FLAKE_HOST="$(
    nix eval --raw "${NIX_DIR}#nixosConfigurations" --apply \
      "cfgs:
         let names = builtins.attrNames cfgs;
         in if builtins.elem \"${HOST_NAME}\" names then \"${HOST_NAME}\"
            else if builtins.length names == 1 then builtins.head names
            else \"\"" 2>/dev/null || true
)"

if [ -z "$FLAKE_HOST" ]; then
    echo "Could not work out which config to build for host '$HOST_NAME'."
    echo "Pick one by hand:"
    echo "  sudo nixos-rebuild switch --flake \"$NIX_DIR#<host>\""
    exit 1
fi

echo "Building configuration '$FLAKE_HOST' from $NIX_DIR."
echo "Nothing is copied to /etc/nixos."
read -r -p "Build and switch now? [y/N] " answer
case "$answer" in
    [yY][eE][sS]|[yY])
        if ! sudo nixos-rebuild switch --flake "${NIX_DIR}#${FLAKE_HOST}" --show-trace; then
            echo ""
            echo "The rebuild failed. Your running system is unchanged."
            exit 1
        fi
        echo ""
        echo "Done. Open a new shell to pick up the 'update-all' helper."
        ;;
    *)
        echo ""
        echo "Skipped. Run this when you are ready:"
        echo "  sudo nixos-rebuild switch --flake \"${NIX_DIR}#${FLAKE_HOST}\""
        echo "After the first rebuild, 'update-all' does the same job."
        ;;
esac
