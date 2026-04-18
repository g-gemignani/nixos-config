{ lib, pkgs }:

let
  mkTheme = import ./mk-theme.nix { inherit lib pkgs; };
  wallpaperImage =
    pkgs.runCommandLocal "hyprland-wallpaper-xnm-macchiato.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 2560x1440 gradient:'#181926-#24273a' \
          -fill 'rgba(139,213,202,0.22)' -draw 'circle 360,260 360,-40' \
          -fill 'rgba(138,173,244,0.16)' -draw 'circle 2140,1140 2140,760' \
          -fill 'rgba(244,219,214,0.07)' -draw 'rectangle 0,0 2559,1439' \
          "$out"
      '';
in
mkTheme {
  name = "xnm-macchiato";
  colors = {
    background = "#181926";
    surface = "#24273a";
    surfaceAlt = "#363a4f";
    surfaceBright = "#494d64";
    border = "#5b6078";
    text = "#cad3f5";
    muted = "#a5adcb";
    primary = "#8bd5ca";
  };
  sansFont = "JetBrains Mono";
  monoFont = "JetBrainsMono Nerd Font";
  surfaceOverlay = "rgba(36, 39, 58, 0.84)";
  wallpaper = wallpaperImage;
  terminalPalette = {
    normal = {
      black = "#24273a";
      red = "#ed8796";
      green = "#a6da95";
      yellow = "#eed49f";
      blue = "#8aadf4";
      magenta = "#f5bde6";
      cyan = "#8bd5ca";
      white = "#cad3f5";
    };
    bright = {
      black = "#5b6078";
      red = "#f38ba8";
      green = "#b7f1a1";
      yellow = "#f9e2af";
      blue = "#9cc2ff";
      magenta = "#f7c8ea";
      cyan = "#9df0e3";
      white = "#f4f7ff";
    };
  };
  gtkThemeName = "catppuccin-macchiato-teal-standard";
  gtkThemePackage = pkgs.catppuccin-gtk;
  iconThemeName = "Colloid-Teal-Dark";
  iconThemePackage = pkgs.colloid-icon-theme;
  cursorName = "Catppuccin-Macchiato-Teal";
  cursorPackage = pkgs.catppuccin-cursors.macchiatoTeal;
  extraPackages = with pkgs; [
    catppuccin-cursors.macchiatoTeal
    catppuccin-gtk
    colloid-icon-theme
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
