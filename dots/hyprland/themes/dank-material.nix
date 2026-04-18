{ lib, pkgs }:

let
  mkTheme = import ./mk-theme.nix { inherit lib pkgs; };
  wallpaperImage =
    pkgs.runCommandLocal "hyprland-wallpaper-dank-material.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 2560x1440 gradient:'#141218-#211f24' \
          -fill 'rgba(208,188,255,0.20)' -draw 'circle 520,180 520,-180' \
          -fill 'rgba(138,180,248,0.12)' -draw 'circle 2120,1200 2120,840' \
          -fill 'rgba(230,224,233,0.05)' -draw 'rectangle 0,0 2559,1439' \
          "$out"
      '';
in
mkTheme {
  name = "dank-material";
  colors = {
    background = "#141218";
    surface = "#211f24";
    surfaceAlt = "#2b292f";
    surfaceBright = "#36343a";
    border = "#948f99";
    text = "#e6e0e9";
    muted = "#cac4cf";
    primary = "#d0bcff";
  };
  sansFont = "Inter";
  monoFont = "FiraCode Nerd Font";
  surfaceOverlay = "rgba(33, 31, 36, 0.84)";
  wallpaper = wallpaperImage;
  terminalPalette = {
    normal = {
      black = "#211f24";
      red = "#cf6679";
      green = "#86d993";
      yellow = "#e7c76e";
      blue = "#8ab4f8";
      magenta = "#d0bcff";
      cyan = "#89dceb";
      white = "#e6e0e9";
    };
    bright = {
      black = "#4a4450";
      red = "#f28b9b";
      green = "#a8efb1";
      yellow = "#f3db8c";
      blue = "#a6c8ff";
      magenta = "#e5d7ff";
      cyan = "#a9eeff";
      white = "#ffffff";
    };
  };
  extraPackages = with pkgs; [
    bibata-cursors
    fira-code
    inter
    materia-theme
    nerd-fonts.fira-code
    papirus-icon-theme
  ];
}
