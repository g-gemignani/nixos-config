# nixos-config

The NixOS and Home Manager configuration for one laptop. The system is built
straight from this repository. Nothing is copied to `/etc/nixos`.

## Layout

| Path | What it holds |
|---|---|
| `flake.nix` | Inputs, and the one host: `nixosConfigurations.gemignani` |
| `nixos/` | System modules, one subject per file |
| `home.nix` | The Home Manager user, and the dotfiles it writes |
| `dots/` | Per-program user configuration |
| `vpn/` | Tunnel definitions and the public OpenVPN profiles |
| `secrets/` | sops-encrypted files. Never commit plain text here |
| `default.nix`, `shell.nix` | Entry points for `nix-build` and `nix-shell` |

`nixos/configuration.nix` imports the other files in `nixos/`. `home.nix`
imports the files in `dots/`.

## Daily use

Rebuild the system with the `update-all` helper, which `dots/bashrc` defines:

```bash
update-all              # rebuild from the current flake.lock
update-all --upgrade    # run `nix flake update` first
```

The helper builds, activates the result for this session, and asks before it
makes the result the default boot generation. If the answer is no, a reboot
returns you to the generation you started from.

The same job by hand:

```bash
sudo nixos-rebuild test   --flake ".#$(hostname)"   # activate, do not touch boot
sudo nixos-rebuild switch --flake ".#$(hostname)"   # activate and make it default
sudo nixos-rebuild build  --flake ".#$(hostname)"   # build only, change nothing
```

CAUTION: A flake build reads git-tracked files only. A new file is invisible
to the rebuild until `git add` picks it up. A commit is not needed. `update-all`
warns about untracked files before it builds.

## Before you commit

```bash
nix fmt                 # nixfmt, the RFC style, on every file
validate-nix-config     # shellcheck, flake check, and the two entry points
```

CI runs the same steps, plus a full evaluation of the system closure. It does
not build the closure: GNOME, Hyprland, wine and steam do not fit on a free
runner.

## Themes

`dots/hyprland/themes/` holds one theme per file, built by `mk-theme.nix`.
`home.nix` selects one with `custom.hyprland.theme`. Hyprland and Alacritty
both read that selection, so the terminal follows the desktop.

## VPN

`vpn/regions.nix` is the only place a tunnel is named. Each entry becomes a
systemd unit and a set of shell helpers:

```bash
vpn-start-it     vpn-stop-it     vpn-status-it
vpn-start-us     vpn-stop-us     vpn-status-us
vpn-start-24     vpn-stop-24     vpn-status-24
```

Two tunnels cannot run together: each unit conflicts with the others, because
they fight over the default route.

A kill switch unit comes up with a tunnel that asks for it. While it is up, the
only traffic that leaves the machine is the tunnel, the local network, and the
handshake that brings the tunnel back. It stops when the last tunnel stops.

WARNING: Do not put a profile that carries a private key in `vpn/`. The Nix
store is world readable. Put the whole `.ovpn` file in sops and name it with
`ovpnSecret`. Read the comment at the top of `vpn/regions.nix`.

## Secrets

`secrets/vpn_secrets.yaml` is encrypted with sops. `.sops.yaml` gives the
recipients: a GPG key, and the age key of the host.

The host key comes from the SSH host key, so `sshd` must stay enabled. It
listens on `127.0.0.1` only and the firewall does not open port 22. Nobody logs
in over it. See the comment in `nixos/network.nix`.

## First install

`install.sh` restores GPG material from a backup folder, then offers the first
rebuild. Read it before you run it.
