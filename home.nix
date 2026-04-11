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
    programs.neovim.withRuby = true;
    programs.neovim.withPython3 = true;

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

    # terminator t4
    programs.terminator = {
      enable = true;
      config = {
        global_config = {
          title_use_system_font = false;
          title_font = "Monospace 10";
        };
        
        profiles.default = {
          # NixOS GNOME Terminal default dark colors
          background_color = "#1e1e1e";
          foreground_color = "#ffffff";
          font = "Monospace 10";
          show_titlebar = false;
          
          # 16-color palette matching NixOS terminal
          palette = "#1e1e1e:#c01c28:#2ec27e:#f5c211:#1e78e4:#9841bb:#0ab9dc:#ffffff:#5e5c64:#ed333b:#57e389:#f8e45c:#51a1ff:#c061cb:#4fd2fd:#ffffff";
          
          # Cursor colors
          cursor_color = "#ffffff";
          
          # Selection colors
          background_darkness = 0.95;
        };
        
        layouts."2x2" = {
          window0 = {
            type = "Window";
            parent = "";
            size = "900, 600";
          };
          child0 = {
            type = "HPaned";
            parent = "window0";
            position = 450;
          };
          child1 = {
            type = "VPaned";
            parent = "child0";
            position = 300;
          };
          terminal1 = {
            type = "Terminal";
            parent = "child1";
            profile = "default";
          };
          terminal2 = {
            type = "Terminal";
            parent = "child1";
            profile = "default";
          };
          child2 = {
            type = "VPaned";
            parent = "child0";
            position = 300;
          };
          terminal3 = {
            type = "Terminal";
            parent = "child2";
            profile = "default";
          };
          terminal4 = {
            type = "Terminal";
            parent = "child2";
            profile = "default";
          };
        };
      };
    };

  };
}
