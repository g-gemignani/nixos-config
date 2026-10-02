# Instructions for a coding agent

Read `README.md` first. It gives the layout, the rebuild commands and the
checks. This file adds only what an agent gets wrong.

## Where things live

Do not look for the VPN units, the sops secrets or the VS Code settings in
`nixos/configuration.nix` or `home.nix`. That file only imports.

- OpenVPN units, the kill switch and `sops.secrets`: `nixos/vpn.nix`
- Tunnel definitions: `vpn/regions.nix`, the one place a tunnel is named
- System packages and the modules that wrap one: `nixos/packages.nix`
- Firewall, DNS and `sshd`: `nixos/network.nix`
- Display manager, fonts, audio and portals: `nixos/desktop.nix`
- Per-program user configuration: `dots/`, one file per program

## Rules

- A flake build reads git-tracked files only. Run `git add` on a new file, or
  the rebuild will not see it.
- `nix fmt` uses nixfmt in the RFC style. Every file already follows it.
- Never write plain-text secrets. `secrets/` holds sops-encrypted files, and
  `.sops.yaml` gives the recipients.
- Never put an OpenVPN profile with a private key in `vpn/`. The Nix store is
  world readable. Use `ovpnSecret` instead.
- Do not change `system.stateVersion` or `home.stateVersion`.
- Do not run `nixos-rebuild switch`. Ask the user. `nixos-rebuild build`
  changes nothing and is the safe check.

## Traps in this repository

- `~/.bashrc` comes from `programs.bash.initExtra`, which reads `dots/bashrc`.
  The build syntax-checks that file, so a broken line fails the rebuild.
- Home Manager writes `home.sessionVariables` to `~/.profile`. A GDM session
  starts through the systemd user manager and never runs a login shell, so
  that file does nothing here. Shell variables belong in `dots/bashrc`.
- `nixos/vpn.nix` builds one `vpn-<key>.service` per entry in
  `vpn/regions.nix`. The `vpn` function in `dots/bashrc` takes the same key,
  so a new entry needs no shell change.
- `custom.hyprland.theme` picks a file in `dots/hyprland/themes/`. The option
  is an enum built by reading that directory, so a new file is a new choice.
  Alacritty reads the loaded theme through `custom.hyprland.themeData`.

## Before you hand back

```bash
nix fmt
nix flake check
nix eval --raw '.#nixosConfigurations.gemignani.config.system.build.toplevel.drvPath'
shellcheck --severity=warning install.sh dots/bashrc
```
