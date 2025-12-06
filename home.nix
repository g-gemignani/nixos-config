{
  pkgs,
  home-manager,
  lib,
  ...
}: {
  home-manager.backupFileExtension = "backup";

  home-manager.users.gemignani = {
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
      direnv
      nixd
    ];

    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./dots/bashrc;
      ".gitconfig".text = builtins.readFile ./dots/gitconfig;
    };

    imports = [
      ./dots/nvim.nix
    ];

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
        };
      };
    };
  };
}
