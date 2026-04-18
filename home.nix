{
  pkgs,
  home-manager,
  lib,
  username,
  ...
}:

{
  home-manager.backupFileExtension = "backup";

  home-manager.users.${username} = {
    nixpkgs.config.allowUnfree = true;
    home.stateVersion = "25.05";

    home.activation.createCodingDir = ''
      mkdir -p "$HOME/Coding"
    '';

    home.packages = with pkgs; [
      alejandra
      wl-clipboard
      black
      isort
      nix-search-cli
      nixfmt
      direnv
      nixd
    ];

    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./dots/bashrc;
      ".gitconfig".text = builtins.readFile ./dots/gitconfig;
    };

    imports = [
      ./dots/alacritty.nix
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
