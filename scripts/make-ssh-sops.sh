#!/usr/bin/env bash
set -euo pipefail

# make-ssh-sops.sh
# Create a tarball of selected SSH keys and encrypt it with sops.
# Usage: ./make-ssh-sops.sh -o secrets/ssh_keys.sops id_ed25519 id_rsa

OUT_PATH="secrets/ssh_keys.sops"
KEYS=()
GPG_RECIPIENTS=()

usage() {
  cat <<'EOF'
Usage: make-ssh-sops.sh [-o outpath] keyfile [keyfile...]

Creates a tarball of the provided key files (relative to $HOME/.ssh),
encrypts it with sops and writes the encrypted file to the repository.

Example:
  ./make-ssh-sops.sh -o secrets/ssh_keys.sops id_ed25519 id_deploy

Security notes:
 - Never commit unencrypted private keys. This script writes a temporary
   tar file under /tmp and removes it after encryption. You must ensure
   your shell and editor do not create backups of the temporary file.
 - The resulting .sops file is safe to commit if you used a secure key.
 - Add the plaintext tar name and any extracted files to .gitignore.
EOF
}

while getopts ":o:h" opt; do
  case "$opt" in
    o) OUT_PATH="$OPTARG" ;;
    r) GPG_RECIPIENTS+=("$OPTARG") ;;
    h) usage; exit 0 ;;
    :) echo "Missing option argument for -$OPTARG" >&2; exit 2 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 1 ]; then
  echo "At least one key file must be provided" >&2
  usage
  exit 2
fi

TMP_DIR=$(mktemp -d)
TAR_FILE="$TMP_DIR/ssh_keys.tar"

trap 'rm -rf "$TMP_DIR"' EXIT

echo "Creating tarball of keys..."
for k in "$@"; do
  # ensure user-provided path doesn't escape ~/.ssh
  src="$HOME/.ssh/$k"
  if [ ! -f "$src" ]; then
    echo "Key not found: $src" >&2
    exit 3
  fi
  tar --transform "s,^,$(basename $k)," -rf "$TAR_FILE" -C "$HOME/.ssh" "$k"
done

echo "Encrypting with sops -> $OUT_PATH"
if ! command -v sops >/dev/null 2>&1; then
  echo "sops is not installed. Please install sops before running this script." >&2
  exit 4
fi

# Ensure the output directory exists
mkdir -p "$(dirname "$OUT_PATH")"

# Use sops to encrypt the tarball. Prefer explicitly passing recipients if
# provided; otherwise attempt to rely on repository `.sops.yaml` creation
# rules. Note: sops matches creation rules against the filename argument it
# is invoked with; since we're encrypting a temporary file, pass the desired
# output path with `--output` so sops may match rules based on that path.
SOPS_ARGS=(--encrypt --input-type binary --output-type binary)
if [ ${#GPG_RECIPIENTS[@]} -gt 0 ]; then
    for r in "${GPG_RECIPIENTS[@]}"; do
      SOPS_ARGS+=(--pgp "$r")
    done
fi

# If no recipients were supplied explicitly, try to extract PGP recipients
# from a repository .sops.yaml (simple heuristic). This helps when sops
# doesn't match creation rules for whatever reason; explicit recipients
# avoid the "no matching creation rules found" error.
if [ ${#GPG_RECIPIENTS[@]} -eq 0 ] && [ -f .sops.yaml ]; then
  echo "no -r provided; attempting to read recipients from .sops.yaml"
  # Extract hex-like tokens from lines with 'pgp' (simple but effective)
  mapfile -t found < <(grep -i "pgp" .sops.yaml -nH | sed -E "s/.*pgp:.*\[(.*)\].*/\1/" | tr -d "'\" " | tr "," "\n" | sed '/^$/d') || true
  if [ ${#found[@]} -gt 0 ]; then
        for r in "${found[@]}"; do
          # basic validation: hex-ish key id
          if [[ "$r" =~ ^[0-9A-Fa-f]{8,}$ ]]; then
            echo "  adding recipient: $r"
            SOPS_ARGS+=(--pgp "$r")
          fi
        done
  fi
fi

if ! sops --help >/dev/null 2>&1; then
  echo "sops not available; aborting" >&2
  exit 4
fi

# Invoke sops with explicit --output so it can inspect the target path for
# creation rules. If creation rules are missing and no recipients were passed,
# sops will emit a helpful error we capture and present.
run_sops() {
  # run sops, capture stderr to a temp file
  local ERRFILE
  ERRFILE=$(mktemp)
  if sops "${SOPS_ARGS[@]}" --output "$OUT_PATH" "$TAR_FILE" 2> "$ERRFILE"; then
    rm -f "$ERRFILE"
    return 0
  else
    # print stderr for debugging
    cat "$ERRFILE" >&2
    grep -qi "no matching creation rules found" "$ERRFILE" && return 2 || return 1
  fi
}

# First try
if run_sops; then
  :
else
  rc=$?
  if [ $rc -eq 2 ]; then
    echo "sops reported no matching creation rules; attempting to re-run with explicit recipients..."
    # try to extract recipients from .sops.yaml if present
    if [ -f .sops.yaml ]; then
      mapfile -t found < <(grep -i "pgp" .sops.yaml -nH | sed -E "s/.*pgp:.*\[(.*)\].*/\1/" | tr -d "'\" " | tr "," "\n" | sed '/^$/d') || true
      if [ ${#found[@]} -gt 0 ]; then
        echo "Found recipients in .sops.yaml: ${found[*]}"
        for r in "${found[@]}"; do
          if [[ "$r" =~ ^[0-9A-Fa-f]{8,}$ ]]; then
            SOPS_ARGS+=(--pgp "$r")
          fi
        done
      fi
    fi

    # If still no recipients, try to extract a keyid from nixos/configuration.nix as a fallback
    if [ ${#SOPS_ARGS[@]} -eq 3 ]; then
      # SOPS_ARGS had only the base args; attempt to find a key in nixos/configuration.nix
      if [ -f nixos/configuration.nix ]; then
        maybe=$(grep -oE "[0-9A-F]{8,16}" nixos/configuration.nix | head -n1 || true)
        if [ -n "$maybe" ]; then
          echo "Adding fallback recipient from nixos/configuration.nix: $maybe"
          SOPS_ARGS+=(--pgp "$maybe")
        fi
      fi
    fi

    # If recipients were added, retry
    if [ ${#SOPS_ARGS[@]} -gt 3 ]; then
      echo "Retrying sops with explicit recipients..."
      # When retrying with explicit recipients, force sops to ignore any
      # repository .sops.yaml by passing an empty config. This avoids the
      # "no matching creation rules found" error while still using the
      # explicit PGP recipients provided.
      SOPS_ARGS+=(--config /dev/null)

      if run_sops; then
        :
      else
        echo "Retry with explicit recipients failed; aborting." >&2
        exit 6
      fi
    else
      echo "No recipients found to retry with; aborting. Provide -r or fix .sops.yaml." >&2
      exit 5
    fi
  else
    echo "sops failed with an unexpected error; see output above." >&2
    exit 1
  fi
fi

echo "Encrypted file created at $OUT_PATH"
echo "Temporary files removed"
