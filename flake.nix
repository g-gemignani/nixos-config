{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    # Make sure home-manager uses the same nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Both follow nixpkgs. Without it the lock carries a second and a third
    # copy of nixpkgs, which is a download and an evaluation for nothing.
    hyprshell.url = "github:H3rmt/hyprshell/hyprshell-release";
    hyprshell.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Always-fresh Claude Code, rebuilt hourly from Anthropic's releases.
    # Overrides nixpkgs' (lagging) claude-code via overlays.default below.
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      sops-nix,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      username = "gemignani";
    in
    {
      # One formatter, so `nix fmt` and the editor agree. nixfmt-tree runs
      # nixfmt in the RFC style on every file. Bare nixfmt with no arguments
      # reads stdin, so `nix fmt` waits for input.
      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          bashInteractive
          git
          nixd
          nixfmt
          sops
        ];
      };

      nixosConfigurations.${username} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            # Replace nixpkgs' claude-code with the hourly-updated flake package.
            nixpkgs.overlays = [ inputs.claude-code.overlays.default ];
          }
          ./nixos/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ./home.nix
        ];

        specialArgs = { inherit inputs username; };
      };
    };
}
