{
  description = "My NixOS configuration";

  inputs = {
    # Add nixpkgs and other necessary inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Add the nix-search-cli flake input
    nix-search-cli.url = "github:peterldowns/nix-search-cli";
  };

  outputs = { self, nixpkgs, nix-search-cli, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations.gemignani = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          # Optional: if the flake provides a module or overlay
          # nix-search-cli.nixosModules.default
        ];

        # Optional: expose the package
        specialArgs = {
          inherit nix-search-cli;
        };
      };
    };
}

