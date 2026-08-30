{
  description = "My NixOS configuration";

  inputs = {
    # Add nixpkgs and other necessary inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    # Make sure home-manager uses the same nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprshell.url = "github:H3rmt/hyprshell/hyprshell-release";

    sops-nix.url = "github:Mic92/sops-nix";

    # Always-fresh Claude Code, rebuilt hourly from Anthropic's releases.
    # Overrides nixpkgs' (lagging) claude-code via overlays.default below.
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      hyprshell,
      home-manager,
      ...
    }@inputs:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      username = "gemignani";
    in
    {
      packages.x86_64-linux = {
        my-nix-search = pkgs.nix-search-cli;
      };

      # One formatter, so `nix fmt` and the editor agree. pkgs.nixfmt is the
      # RFC-style build, which is what every file in this repo already uses.
      formatter.x86_64-linux = pkgs.nixfmt;

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          bashInteractive
          git
          nixd
          nixfmt
          sops
        ];
      };

      nixosConfigurations.${username} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { config, ... }:
            {
              nixpkgs.config.allowUnfree = true;
              # Replace nixpkgs' claude-code with the hourly-updated flake package.
              nixpkgs.overlays = [ inputs.claude-code.overlays.default ];
            }
          )
          ./nixos/configuration.nix
          sops-nix.nixosModules.sops # Now this will be correctly referenced
          home-manager.nixosModules.home-manager
          ./home.nix
        ];

        # Optional: expose the package and pass username to modules
        specialArgs = {
          inherit inputs;
          username = username;
        };
      };
    };
}
