{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  availableThemeFiles = builtins.attrNames (builtins.readDir ./hyprland/themes);
  themeNames = builtins.filter (name: name != "mk-theme") (
    map (name: lib.removeSuffix ".nix" name) (
      builtins.filter (name: lib.hasSuffix ".nix" name) availableThemeFiles
    )
  );
  cfg = config.custom.hyprland;
  theme = import (./hyprland/themes + "/${cfg.theme}.nix") { inherit lib pkgs; };
in
{
  options.custom.hyprland = {
    theme = lib.mkOption {
      type = lib.types.enum themeNames;
      default = "dank-material";
      description = "Selected Hyprland theme variant shared by Hyprland and Alacritty.";
    };

    # The loaded theme, so dots/alacritty.nix does not have to know where the
    # theme files live or how they are called.
    themeData = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      description = "The theme that custom.hyprland.theme selects, already loaded.";
    };
  };

  config = lib.mkMerge [
    { custom.hyprland.themeData = theme; }
    (import ./hyprland/core.nix {
      inherit
        config
        inputs
        lib
        pkgs
        theme
        ;
    })
  ];
}
