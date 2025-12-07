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
      ".local/bin/make-ssh-sops.sh".source = ./scripts/make-ssh-sops.sh;
    };

    imports = [
      ./dots/nvim.nix
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

    # Home activation: decrypt sops-encrypted SSH keys (optional)
    home.activation.decryptSopsSshKeys = lib.mkIf (builtins.pathExists ./secrets/ssh_keys.sops) (
      builtins.readFile ./scripts/decrypt-ssh-keys.sh
    );

    # Added: VS Code + Nix IDE + settings for nixd
    programs.vscode = {
      enable = true;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          ms-python.python
        ];
        userSettings = {
          "nix.serverPath" = "nixd";
          "editor.formatOnSave" = true;
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "github.copilot.nextEditSuggestions.enabled" = true;
        };
      };
    };
  };
}
