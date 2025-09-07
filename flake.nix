{
  description = "My NixOS configuration";

  inputs = {
    # Add nixpkgs and other necessary inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    # Make sure home-manager uses the same nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Add the nix-search-cli flake input
    nix-search-cli.url = "github:peterldowns/nix-search-cli";
  };

  outputs = {
    self,
    nixpkgs,
    nix-search-cli,
    home-manager,
    ...
  } @ inputs: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    packages.x86_64-linux = {
      my-nix-search = pkgs.nix-search-cli;
    };

    nixosConfigurations.gemignani = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/configuration.nix
        home-manager.nixosModules.home-manager
        ./home.nix
      ];

      # Optional: expose the package
      specialArgs = {
        inherit nix-search-cli;
      };
    };
  };
}
