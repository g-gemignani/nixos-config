{
  description = "My NixOS configuration";

  inputs = {
    # Add nixpkgs and other necessary inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    # Make sure home-manager uses the same nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Add the nix-search-cli flake input
    nix-search-cli.url = "github:peterldowns/nix-search-cli";
  };

  outputs = { self, nixpkgs, nix-search-cli, home-manager, ... } @ inputs: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    username = "gemignani";
  in {
      packages.x86_64-linux = {
        my-nix-search = pkgs.nix-search-cli;
      };

      nixosConfigurations.${username} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { config, ... }:
            {
              nixpkgs.config.allowUnfree = true;
            }
          )
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          ./home.nix
        ];

        # Optional: expose the package and pass username to modules
        specialArgs = {
          inherit nix-search-cli;
          username = username;
        };
      };
    };
}
