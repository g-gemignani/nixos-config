#!/usr/bin/env bash

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

# Call update-all
update-all
