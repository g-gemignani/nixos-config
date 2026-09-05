# Non-flake entry point. `nix-build` gives the same system closure as
# `nixos-rebuild --flake`.
let
  flake = import (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      nodeName = lock.nodes.root.inputs.flake-compat;
    in
    fetchTarball {
      url =
        lock.nodes.${nodeName}.locked.url
          or "https://github.com/NixOS/flake-compat/archive/${lock.nodes.${nodeName}.locked.rev}.tar.gz";
      sha256 = lock.nodes.${nodeName}.locked.narHash;
    }
  ) { src = ./.; };

  # The flake defines one host. Reading its name here keeps this file from
  # repeating the user name that flake.nix already holds.
  configs = flake.outputs.nixosConfigurations;
  host = builtins.head (builtins.attrNames configs);
in
configs.${host}.config.system.build.toplevel
