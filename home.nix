{
  pkgs,
  home-manager,
  lib,
  ...
}: {
  home-manager.backupFileExtension = "backup";
  home-manager.users.gemignani = {
    home.stateVersion = "25.05";
    home.activation.createCodingDir = ''
      mkdir -p "$HOME/Coding"
    '';
    home.packages = with pkgs; [
      alejandra # strict, used in nixpkgs
      wl-clipboard
      black
      isort
      nix-search-cli
    ];

    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./dots/bashrc;
      ".gitconfig".text = builtins.readFile ./dots/gitconfig;
    };

    imports = [
      ./dots/nvim.nix
    ];
  };
}
