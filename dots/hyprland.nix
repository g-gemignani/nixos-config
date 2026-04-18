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
  options.custom.hyprland.theme = lib.mkOption {
    type = lib.types.enum themeNames;
    default = "midnight";
    description = "Selected Hyprland theme variant shared by Hyprland and Alacritty.";
  };

  config = import ./hyprland/core.nix {
    inherit
      config
      inputs
      lib
      pkgs
      theme
      ;
  };
}
