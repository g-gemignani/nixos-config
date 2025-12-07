#!/usr/bin/env bash
set -euo pipefail

# decrypt-ssh-keys.sh
# Safely decrypts `vpn/ssh_keys.sops` into the user's `~/.ssh`.

NIX_DIR=${NIX_DIR:-"$HOME/nixos-config"}

# Simple CLI: --dry-run and --verbose
DRY_RUN=0
VERBOSE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift ;;
    --verbose|-v) VERBOSE=1; shift ;;
    --force|-f) FORCE=1; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done

log() { if [ "$VERBOSE" -eq 1 ]; then printf '[decrypt-ssh-keys] %s\n' "$*" >&2; fi }

if ! command -v sops >/dev/null 2>&1; then
  echo "sops not available; skipping SSH key decryption" >&2
  exit 0
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" || true

# decrypt `secrets/ssh_keys.sops` into ~/.ssh, keeping strict perms
SOPS_FILE="$NIX_DIR/secrets/ssh_keys.sops"
if [ -f "$SOPS_FILE" ]; then
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  AUTH_TMP="$TMP_DIR/ssh_keys"

  log "Decrypting $SOPS_FILE to temporary file"
  if sops --output-type binary --output "$AUTH_TMP" --decrypt "$SOPS_FILE" 2>/dev/null; then
    chmod 600 "$AUTH_TMP" || true

    # Determine if the decrypted blob is a tar archive by testing tar listing
    if tar -tf "$AUTH_TMP" >/dev/null 2>&1; then
      log "Detected tar archive — extracting to temporary directory"
      EXTRACT_DIR="$TMP_DIR/extracted"
      mkdir -p "$EXTRACT_DIR"
      tar -xf "$AUTH_TMP" -C "$EXTRACT_DIR"

      # Move files into ~/.ssh with safe perms and no partial overwrites
      for f in "$EXTRACT_DIR"/*; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        dest="$HOME/.ssh/$base"
        if [ "$DRY_RUN" -eq 1 ]; then
          log "DRY RUN: would install $f -> $dest"
        else
          if [ -e "$dest" ] && [ "${FORCE:-0}" != 1 ]; then
            log "Skipping existing $dest (use --force to overwrite)"
            continue
          fi
          install -m 600 -o "$USER" -g "$USER" "$f" "$dest" 2>/dev/null || cp -p "$f" "$dest"
          # set public key perms if ends with .pub
          if [[ "$base" == *.pub ]]; then
            chmod 644 "$dest" || true
          else
            chmod 600 "$dest" || true
          fi
          log "Installed $dest"
        fi
      done
    else
      log "Single-file key detected — writing to $HOME/.ssh/id_deploy"
      if [ "$DRY_RUN" -eq 1 ]; then
        log "DRY RUN: would move $AUTH_TMP -> $HOME/.ssh/id_deploy"
      else
        if [ -e "$HOME/.ssh/id_deploy" ] && [ "${FORCE:-0}" != 1 ]; then
          log "Skipping existing $HOME/.ssh/id_deploy (use --force to overwrite)"
        else
          mv "$AUTH_TMP" "$HOME/.ssh/id_deploy"
          chmod 600 "$HOME/.ssh/id_deploy" || true
          chown "$USER":"$USER" "$HOME/.ssh/id_deploy" 2>/dev/null || true
          log "Installed $HOME/.ssh/id_deploy"
        fi
      fi
    fi

    # explicit cleanup is handled by trap
  else
    echo "sops decryption failed; skipping" >&2
  fi
fi


# Try to add private keys to the ssh agent. It's OK if no agent is
# present; we simply skip adding in that case.
if command -v ssh-add >/dev/null 2>&1; then
    if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        for key in "$HOME/.ssh"/*; do
        [ -f "$key" ] || continue
        case "$key" in
            *.pub) continue ;;
        esac
        chmod 600 "$key" || true
        ssh-add "$key" 2>/dev/null || true
        done
    else
        # No socket available; skip adding keys.
        true
    fi
fi

exit 0
