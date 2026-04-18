{
  config,
  lib,
  pkgs,
  ...
}:

let
  theme = import (./hyprland/themes + "/${config.custom.hyprland.theme}.nix") { inherit lib pkgs; };
in
{
  xdg.mimeApps = {
    associations.added = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
  };

  programs.alacritty = {
    enable = true;
    settings = lib.recursiveUpdate {
      keyboard.bindings = [
        {
          key = "N";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];
      window = {
        padding = {
          x = 24;
          y = 26;
        };
      };
    } theme.alacrittySettings;
  };
}
