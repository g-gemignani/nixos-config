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
    home.file.".gitconfig".text = builtins.readFile ./dots/gitconfig;

    # The module owns ~/.bashrc, so every other Home Manager module can add
    # its own shell hook. Writing the file by hand with home.file cut those
    # off, and home.sessionVariables with it.
    #
    # initExtra lands in the interactive part of the file, which is where
    # everything in dots/bashrc belongs. The build runs a syntax check on the
    # result, so a broken line fails the rebuild instead of the next shell.
    programs.bash = {
      enable = true;
      initExtra = builtins.readFile ./dots/bashrc + vpnHelpers;
    };

    # direnv on its own re-evaluates the flake on every cd into a project.
    # nix-direnv caches that. programs.bash above is what lets this module
    # install its own hook, so dots/bashrc no longer carries one.
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

    # No home.sessionVariables here. Home Manager exports them from ~/.profile,
    # and a GDM session starts through the systemd user manager, which never
    # runs a login shell. So .profile is dead on this machine and every
    # variable it held was set a second time in dots/bashrc anyway. That file
    # is the one place a shell variable lives. SSH_AUTH_SOCK is set there.

    # possible themes:
    # - "dank-material"
    # - "midnight"
    # - "simp1e-late-night"
    # - "xnm-macchiato"

    custom.hyprland.theme = "dank-material";
  };
}
