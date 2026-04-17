{
  config,
  lib,
  pkgs,
  ...
}:

let
  themeName = "midnight";
  theme = import (./hyprland/themes + "/${themeName}.nix") { inherit lib pkgs; };
in
import ./hyprland/core.nix {
  inherit
    config
    lib
    pkgs
    theme
    ;
}
