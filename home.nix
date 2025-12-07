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
      ".vpn/README".text = ''
        This directory is intended for local VPN configs and secrets.

        - Put your provider .ovpn file here, e.g. ~/.vpn/myprovider.ovpn
        - If required, create ~/.vpn/auth.txt with two lines: username then password
        - Protect secrets: `chmod 600 ~/.vpn/auth.txt`
        - Start with: `sudo openvpn --config ~/.vpn/myprovider.ovpn --auth-user-pass /path/to/auth` or use the `vpn-up` helper
        Do NOT commit files from this directory to git.
      '';
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
          "github.copilot.nextEditSuggestions.enabled" = true;
        };
      };
    };
  };
}
