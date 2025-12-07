#!/bin/sh
set -euo pipefail

log() { printf '%s: %s\n' "sops-vpn" "$1" >&2; }

# Runtime-configurable variables (substituted by Nix)
GNUPG_BIN='@@GNUPG_BIN@@'
SOPS_BIN='@@SOPS_BIN@@'
RUNUSER_BIN='@@RUNUSER_BIN@@'
VPN_DIR='@@VPN_DIR@@'
KEYID='@@KEYID@@'
DECRYPT_USER='@@DECRYPT_USER@@'
OVPN_FILE='@@OVPN_FILE@@'
AUTH_SOPS='@@AUTH_SOPS@@'
AUTH_OUT='@@AUTH_OUT@@'
GPG_PRIVATE_PATH='@@GPG_PRIVATE_PATH@@'

# Runtime directory for transient files (ideally provided via systemd RuntimeDirectory)
RUNTIME_DIR='/run/sops-vpn'

log 'starting combined import+decrypt activation'

mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR" || true

# Validate required binaries
if [ ! -x "$GNUPG_BIN" ]; then
  log "missing gpg binary: $GNUPG_BIN"
  exit 0
fi
if [ ! -x "$SOPS_BIN" ]; then
  log "sops not available at $SOPS_BIN"
  exit 0
fi

# Create a transient keyring and import minimal key material
KEYRING_DIR="$RUNTIME_DIR/keyring"
mkdir -p "$KEYRING_DIR"
chmod 700 "$KEYRING_DIR"

# We use a separate keyring to avoid touching the system/user keyrings
KEYRING_FILE="$KEYRING_DIR/pubring.kbx"

import_user_key() {
  user_home="$1"
  if [ -z "$user_home" ] || [ ! -d "$user_home/.gnupg" ]; then
    return 1
  fi

  # Try exporting the minimal secret key material for KEYID from the user's homedir
  if [ -n "$DECRYPT_USER" ]; then
    # Use runuser to read user's homedir without relying on their environment
    if "$RUNUSER_BIN" -u "$DECRYPT_USER" -- "$GNUPG_BIN" --homedir "$user_home/.gnupg" --export-secret-keys --armor "$KEYID" | \
       "$GNUPG_BIN" --no-default-keyring --keyring "$KEYRING_FILE" --import; then
      log "imported key $KEYID from user $DECRYPT_USER into transient keyring"
      return 0
    fi
  fi
  return 1
}

# Prefer an explicit root-provided private key if present
if [ -f "$GPG_PRIVATE_PATH" ]; then
  if "$GNUPG_BIN" --no-default-keyring --keyring "$KEYRING_FILE" --import "$GPG_PRIVATE_PATH"; then
    log "imported root-provided private key"
  else
    log "failed to import root-provided private key"
  fi
else
  # Attempt to import from a configured user (if set)
  if [ -n "$DECRYPT_USER" ]; then
    USER_HOME=$(getent passwd "$DECRYPT_USER" | cut -d: -f6 || true)
    import_user_key "$USER_HOME" || log "no key imported from user $DECRYPT_USER"
  fi
fi

# If no keys available, exit gracefully (nothing to do)
if ! "$GNUPG_BIN" --no-default-keyring --keyring "$KEYRING_FILE" --list-keys >/dev/null 2>&1; then
  log "no GPG keys available in transient keyring; skipping sops decrypt"
  exit 0
fi

# Ensure VPN output dir exists and place OVPN file atomically
AUTH_TMP="$RUNTIME_DIR/auth.txt.tmp"
AUTH_FINAL="$AUTH_OUT"
mkdir -p "$(dirname "$AUTH_FINAL")"

if [ -f "$VPN_DIR/$OVPN_FILE" ]; then
  install -m 644 "$VPN_DIR/$OVPN_FILE" "/etc/openvpn/$OVPN_FILE" || log "warning: failed to install ovpn file"
fi

# Decrypt with retries (bounded, short backoff)
max_attempts=6
attempt=1
while [ $attempt -le $max_attempts ]; do
  if "$SOPS_BIN" --output "$AUTH_TMP" --decrypt --input-type binary "$VPN_DIR/$AUTH_SOPS" 2>/dev/null; then
    install -m 600 "$AUTH_TMP" "$AUTH_FINAL"
    rm -f "$AUTH_TMP" || true
    log "decrypt succeeded and wrote credentials to $AUTH_FINAL"
    break
  else
    log "decrypt attempt $attempt failed"
    attempt=$((attempt+1))
    sleep $((attempt))
  fi
done

if [ $attempt -gt $max_attempts ]; then
  log "decrypt failed after $max_attempts attempts; removing any partial files"
  rm -f "$AUTH_TMP" || true
  rm -f "$AUTH_FINAL" || true
  exit 1
fi

# Cleanup transient key material (don't leave secret keys behind)
rm -rf "$KEYRING_DIR" || true

exit 0
