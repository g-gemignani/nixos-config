{ pkgs, home-manager, ... }: {

  home-manager.backupFileExtension = "backup";
  home-manager.users.gemignani = {

    home.stateVersion = "25.05";


    # Dotfiles
    home.file = {
      ".bashrc".text = builtins.readFile ./bashrc;
    };

    # Neovim setup
    programs.neovim = {
      enable = true;
      withPython3 = true;
    };

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

