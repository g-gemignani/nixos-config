
# Repository overview

This repository contains a personal NixOS + Home Manager configuration (flake-based). It is organized to be used both as a system `nixos/` configuration and as a user `home.nix` via the flake in `flake.nix`.

Key goals for an AI coding agent working here:
- Understand the flake-driven layout (`flake.nix`) and how `nixos/configuration.nix` and `home.nix` are imported.
- Preserve safety around secrets: the repo uses `sops`-encrypted files under `secrets/` and helper scripts in `scripts/`.
- Prefer minimal, targeted edits: keep changes localized to relevant Nix files and scripts.

**Big picture / architecture**
- `flake.nix` ties inputs (nixpkgs, home-manager) and exposes `nixosConfigurations.<username>`; it assembles system modules including `./nixos/configuration.nix` and `./home.nix`.
- `nixos/configuration.nix` contains system-level options, packages, and systemd services (e.g. Surfshark OpenVPN units and an activation script built from `scripts/sops-vpn.sh`).
- `home.nix` configures the user environment via Home Manager: dotfiles (`dots/`), packages, VS Code settings, and session variables.
- `scripts/` contains helper scripts for sops-encryption (`make-ssh-sops.sh`) and decryption/activation (`decrypt-ssh-keys.sh`, `sops-vpn.sh`). These are executed manually or via activation scripts.

**Data flows and secrets**
- Encrypted secrets live in `secrets/*.sops`. `make-ssh-sops.sh` produces `secrets/ssh_keys.sops`; `decrypt-ssh-keys.sh` reads it and writes to `~/.ssh/`.
- `nixos/configuration.nix` includes an `activationScripts.sops-vpn` which substitutes variables into `scripts/sops-vpn.sh` at activation time to produce `/etc/openvpn/auth.txt` for systemd OpenVPN units.

**Project-specific conventions**
- `NIX_DIR` environment variable: many scripts expect `NIX_DIR` (default `~/nixos-config`). Dotfiles export it in `dots/bashrc` and `install.sh` adds it when invoked.
- GPG / SSH agent: The configuration expects `gpg-agent` with SSH support. `home.nix` sets `SSH_AUTH_SOCK` to `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh` and `dots/bashrc`/scripts try to use this socket.
- sops usage: prefer calling sops with `--output` so creation rules match the target filename (see `scripts/make-ssh-sops.sh`); scripts attempt to discover PGP recipients from `.sops.yaml` or `nixos/configuration.nix` if needed.
- Do not commit unencrypted secret material. The repo includes `.sops.yaml` and `secrets/*.sops` and helper scripts assume sops is installed on the machine.

**Developer workflows / common commands**
- Update the flake, copy files and rebuild system (used by `install.sh` / `update-all` alias):

```bash
cd $NIX_DIR         # default: $HOME/nixos-config
nix flake update
sudo cp -r ./* /etc/nixos/
sudo nixos-rebuild switch --upgrade --show-trace
```

- Rebuild only the user's Home Manager configuration (when iterating on `home.nix`):

```bash
nix build .#homeConfigurations.${USER}.activationPackage
./result/activate
```

- Encrypt SSH keys into the repo (example):

```bash
./scripts/make-ssh-sops.sh -o secrets/ssh_keys.sops id_ed25519 id_deploy
```

- Decrypt SSH keys locally (safe install into `~/.ssh`):

```bash
./scripts/decrypt-ssh-keys.sh --verbose
```

**Files worth editing with caution (examples)**
- `flake.nix` — changes affect how the flake exposes system and home configurations.
- `nixos/configuration.nix` — system packages, services, activation scripts. Example: Surfshark systemd services and `system.activationScripts.sops-vpn`.
- `home.nix` — user packages, dotfile wiring in `home.file`, VS Code settings under `programs.vscode.profiles.default`.
- `scripts/*.sh` — shell helpers that manipulate secrets and activation scripts. Ensure `set -euo pipefail` and permission handling are preserved.

**Patterns & examples an agent should follow**
- When editing Nix files, preserve the existing option structure and `lib`/`pkgs` parameterization used by the module functions (e.g., modules are written as `{ config, lib, pkgs, ... }:`).
- Prefer adding options or small helper modules over large rewrites. Keep `system.stateVersion` unchanged without explicit migration steps.
- For scripts that touch secrets, keep strict file permissions (600 for private keys) and the existing temporary-file cleanup `trap` logic.

**Testing / validation steps an agent should run locally**
- Syntax-check Nix expressions before committing:

```bash
nix eval --json .#nixosConfigurations.${USER}  # quick check of flake outputs
nix flake check || true                       # run checks if available
```

- Try a dry-run for rebuilds on test machines or in local VM before pushing updates to a production device.

**What not to change without asking**
- Any modifications that expose plaintext credentials or weaken sops usage.
- Replacing `system.stateVersion` or wholesale changes that require manual migrations.

If any section is unclear or you want more detail (e.g., sample `nix build` outputs, more VS Code settings, or guidance for adding a new systemd service), tell me which area to expand and I will iterate.

**Key files & examples**
- `flake.nix`: shows how `home-manager` is wired into `nixosConfigurations.<username>` and how `specialArgs` (e.g., `username`, `nix-search-cli`) are passed.
- `home.nix`: Home Manager user config. Examples:
	- Dotfiles wired via `home.file` (`.bashrc` and `.gitconfig`).
	- `home.sessionVariables` setting `SSH_AUTH_SOCK` to `"$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"`.
	- VS Code profile settings under `programs.vscode.profiles.default.userSettings`.
- `nixos/configuration.nix`: System config. Examples:
	- `environment.systemPackages` lists installed system packages (e.g., `openvpn`, `sops`).
	- `system.activationScripts.sops-vpn` injects values into `scripts/sops-vpn.sh` to write `/etc/openvpn/auth.txt`.
	- `systemd.services.surfshark-openvpn-*` units that rely on `/etc/openvpn/auth.txt` created by the activation script.
- `scripts/make-ssh-sops.sh`: creates and encrypts a tarball of SSH keys; prefers `sops --output` so creation rules match target filename.
- `scripts/decrypt-ssh-keys.sh`: decrypts `secrets/ssh_keys.sops` safely into `~/.ssh/`, preserves permissions, and attempts to add keys to agent.

