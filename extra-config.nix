{ config, pkgs, ... }:

{
  imports =
  [
    <home-manager/nixos>
  ];

  # Enable Home Manager for your user (e.g., 'your-username')
  home-manager.users.gemignani = { 
    home.file = {
      "/home/your-username/.bashrc" = pkgs.writeText "custom-bashrc" ''
        # Your custom .bashrc content goes here
        export PATH=$PATH:/your/custom/path
        alias ll='ls -la'
      '';
    };
  };

  programs.neovim ={
    enable = true;
    withPython3 = true;
  };

  # Define custom .bashrc for a specific user
  home.file = {
    "/home/gemignani/.bashrc" = pkgs.writeText "custom-bashrc" ''
      # Your custom .bashrc content goes here
      bind '"\e[A":history-search-backward'
      bind '"\e[B":history-search-forward'
      
      forgit() {
        for file in $(ls -d */); do cd $file; echo "----$file-----"; git $@; cd ..; done
      }

      recursive_replace()
      {
        if [ $# -eq 2 ]; then
          command="grep -rl --exclude-dir='.git' $1 ./ | xargs sed -i 's/${1}/${2}/g'"
          echo "running: $command"
	  eval $command
	elif [ $# -eq 3 ]; then
	  command="grep -rl --exclude-dir='.git' $2 $1 | xargs sed -i 's/${2}/${3}/g'"
	  echo "running: $command"
	  eval $command
	else
	  echo "Illegal number of arguments"
	fi
      }
      # Add more customizations as needed
    '';
  };



}
