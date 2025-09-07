{
  pkgs,
  home-manager,
  ...
}: {
  home-manager.backupFileExtension = "backup";
  home-manager.users.gemignani = {
    home.stateVersion = "25.05";

    home.packages = with pkgs; [
      alejandra # strict, used in nixpkgs
      wl-clipboard
      black
      isort
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
