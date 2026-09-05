{
  pkgs,
  home-manager,
  lib,
  inputs,
  username,
  ...
}:

let
  regions = import ./vpn/regions.nix;

  # Generated from the same list that builds the systemd units, so a new
  # region never leaves the shell helpers behind.
  vpnHelpers = lib.concatStrings (
    lib.mapAttrsToList (key: _region: ''

      vpn-start-${key}() {
        sudo systemctl start vpn-${key}.service
      }

      vpn-stop-${key}() {
        sudo systemctl stop vpn-${key}.service
      }

      vpn-status-${key}() {
        sudo systemctl status vpn-${key}.service
      }
    '') regions
  );
in
{
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };

  home-manager.users.${username} = {
    nixpkgs.config.allowUnfree = true;
    home.stateVersion = "25.05";

    home.activation.createCodingDir = ''
      mkdir -p "$HOME/Coding"
    '';

    home.packages = with pkgs; [
      wl-clipboard
      black
      isort
      nix-search-cli
      nixfmt
      nixd
      # Claude Code plugin hooks (ponytail) run node scripts.
      nodejs
    ];

    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./dots/bashrc + vpnHelpers;
      ".gitconfig".text = builtins.readFile ./dots/gitconfig;
    };

    # direnv on its own re-evaluates the flake on every cd into a project.
    # nix-direnv caches that. The bash hook stays in dots/bashrc: the module
    # writes its hook through programs.bash, which this config does not use.
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    imports = [
      inputs.hyprshell.homeModules.hyprshell
      ./dots/alacritty.nix
      ./dots/gnome.nix
      ./dots/hyprland.nix
      ./dots/nvim.nix
      ./dots/vscode.nix
    ];

    # NOTE: configure gpg-agent either in the system `nixos/configuration.nix`
    # (see `programs.gnupg.agent = { ... }`) or in a Home Manager module. Avoid
    # declaring `programs.gnupg` here when this file is used as a NixOS module
    # via `flake.nix` to prevent option evaluation errors.

    # Export SSH_AUTH_SOCK to point at the user run-time gpg-agent ssh socket
    # if present at runtime. This sets the default for shells started after
    # home-manager activation; it's harmless if the socket doesn't exist.
    home.sessionVariables = lib.mkMerge [
      (lib.optionalAttrs true {
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
      })
    ];
    # possible themes:
    # - "dank-material"
    # - "midnight"
    # - "simp1e-late-night"
    # - "xnm-macchiato"

    custom.hyprland.theme = "dank-material";
  };
}
