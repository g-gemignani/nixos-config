{
  pkgs,
  inputs,
  username,
  ...
}:

{
  home-manager.backupFileExtension = "backup";
  # Use the system pkgs, so Home Manager does not evaluate nixpkgs a second
  # time and the overlays and allowUnfree in flake.nix apply here too.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };

  home-manager.users.${username} = {
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
      # Voice mode in Claude Code records with `rec`, which sox gives.
      sox
    ];

    # Dotfiles
    home.file.".gitconfig".source = ./dots/gitconfig;

    # The module owns ~/.bashrc, so every other Home Manager module can add
    # its own shell hook. Writing the file by hand with home.file cut those
    # off, and home.sessionVariables with it.
    #
    # initExtra lands in the interactive part of the file, which is where
    # everything in dots/bashrc belongs. The build runs a syntax check on the
    # result, so a broken line fails the rebuild instead of the next shell.
    programs.bash = {
      enable = true;
      initExtra = builtins.readFile ./dots/bashrc;
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
      ./dots/keepass.nix
      ./dots/nvim.nix
      ./dots/vscode.nix
      ./dots/zed.nix
    ];

    # No home.sessionVariables here. Home Manager exports them from ~/.profile,
    # and a GDM session starts through the systemd user manager, which never
    # runs a login shell. So .profile is dead on this machine and every
    # variable it held was set a second time in dots/bashrc anyway. That file
    # is the one place a shell variable lives. SSH_AUTH_SOCK is set there.

    # One file in dots/hyprland/themes per theme. Only dank-material exists.
    custom.hyprland.theme = "dank-material";

    # Home Manager owns ~/.config/mimeapps.list, so the default apps live here
    # and in the dots/ module of each app. The file is read-only: an app that
    # tries to make itself the default fails, and the change goes here.
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
        "application/pdf" = "google-chrome.desktop";
        # Claude Code writes this desktop file to ~/.local/share/applications.
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      };
    };
  };
}
