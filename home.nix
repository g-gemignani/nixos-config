{
  pkgs,
  home-manager,
  ...
}: {
  home-manager.backupFileExtension = "backup";
  home-manager.users.gemignani = {
    home.stateVersion = "25.05";

    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./dots/bashrc;
    };

    imports = [
      ./dots/nvim.nix
    ];

    home.packages = with pkgs; [
      alejandra # strict, used in nixpkgs
      black
      isort
    ];

    # Git setup
    programs.git = {
      enable = true;
      userName = "g-gemignani";
      userEmail = "guglielmogemignani@gmail.com";

      extraConfig = {
        core.editor = "nvim";
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };
}
