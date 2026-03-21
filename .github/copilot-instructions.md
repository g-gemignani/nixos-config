
# Repository overview

This repository contains a personal NixOS + Home Manager configuration (flake-based). It is organized to be used both as a system `nixos/` configuration and as a user `home.nix` via the flake in `flake.nix`.

Key goals for an AI coding agent working here:
- Understand the flake-driven layout (`flake.nix`) and how `nixos/configuration.nix` and `home.nix` are imported.
- Preserve safety around secrets: the repo uses `sops`-encrypted files under `secrets/` and bootstrap/update helpers in `install.sh` and `dots/bashrc`.
- Prefer minimal, targeted edits: keep changes localized to relevant Nix files and scripts.

**Big picture / architecture**
- `flake.nix` ties inputs (nixpkgs, home-manager, sops-nix) and exposes `nixosConfigurations.<username>`; it assembles system modules including `./nixos/configuration.nix` and `./home.nix`.
- `default.nix` is the non-flake compatibility entrypoint via `flake-compat`, so legacy `nix-build` style workflows can still resolve the system closure.
- `nixos/configuration.nix` contains system-level options, packages, and systemd services (e.g. Surfshark OpenVPN units wired to a sops-managed secret).
- `home.nix` configures the user environment via Home Manager: dotfiles (`dots/`), packages, VS Code settings, and session variables.
- `install.sh` restores GPG state from a backup, while `dots/bashrc` defines local quality-of-life helpers such as `update-all` and VPN service wrappers.

**Data flows and secrets**
- Encrypted secrets live under `secrets/` and are decrypted through `sops-nix` at activation/runtime.
- `nixos/configuration.nix` declares `sops.secrets.vpn_auth` from `secrets/vpn_secrets.yaml`, and the Surfshark OpenVPN services read the resulting secret path directly via `config.sops.secrets.vpn_auth.path`.

**Project-specific conventions**
- `NIX_DIR` environment variable: local shell helpers expect `NIX_DIR` (default `~/nixos-config`). `dots/bashrc` sets a default if it is not already exported by the environment.
- GPG / SSH agent: The configuration expects `gpg-agent` with SSH support. `home.nix` sets `SSH_AUTH_SOCK` to `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh` and `dots/bashrc`/scripts try to use this socket.
- Do not commit unencrypted secret material. The repo includes `.sops.yaml` and encrypted files under `secrets/`; the runtime assumes `sops` is installed on the machine.

**Developer workflows / common commands**
- Update the flake, copy files and rebuild system (used by the `update-all` shell helper):

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

- Enter the repository development shell without native flake support:

```bash
nix-shell
```

- Run the local validation helper before rebuilding:

```bash
validate-nix-config
```

- Restore local GPG material from a backup folder:

```bash
./install.sh
```

**Files worth editing with caution (examples)**
- `flake.nix` — changes affect how the flake exposes system and home configurations.
- `default.nix` — compatibility shim for non-flake tooling; keep it aligned with `flake.lock` and the exported host name.
- `shell.nix` — compatibility shim for non-flake development shells; keep it aligned with the default flake dev shell.
- `nixos/configuration.nix` — system packages, services, and sops-managed VPN wiring. Example: Surfshark systemd services and `sops.secrets.vpn_auth`.
- `home.nix` — user packages, dotfile wiring in `home.file`, VS Code settings under `programs.vscode.profiles.default`.
- `install.sh` and `dots/bashrc` — local bootstrap/update helpers. Preserve `set -euo pipefail`, quoting, and permission handling.

**Patterns & examples an agent should follow**
- When editing Nix files, preserve the existing option structure and `lib`/`pkgs` parameterization used by the module functions (e.g., modules are written as `{ config, lib, pkgs, ... }:`).
- Prefer adding options or small helper modules over large rewrites. Keep `system.stateVersion` unchanged without explicit migration steps.
- For scripts that touch secrets, keep strict file permissions and avoid writing machine-specific state back into tracked dotfiles.

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
- `default.nix`: bridges non-flake tooling to the flake outputs via `flake-compat`.
- `shell.nix`: bridges non-flake `nix-shell` usage to the flake dev shell via `flake-compat`.
- `home.nix`: Home Manager user config. Examples:
	- Dotfiles wired via `home.file` (`.bashrc` and `.gitconfig`).
	- `home.sessionVariables` setting `SSH_AUTH_SOCK` to `"$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"`.
	- VS Code profile settings under `programs.vscode.profiles.default.userSettings`.
- `nixos/configuration.nix`: System config. Examples:
	- `environment.systemPackages` lists installed system packages (e.g., `openvpn`, `sops`).
	- `sops.secrets.vpn_auth` exposes the decrypted VPN credentials to systemd units.
	- `systemd.services.surfshark-openvpn-*` units read the sops-managed credential path directly.
- `install.sh`: restores GPG backups into `~/.gnupg`, preserves permissions, and leaves the rebuild step explicit.
- `dots/bashrc`: defines `update-all`, VPN helpers, and small utility functions.

