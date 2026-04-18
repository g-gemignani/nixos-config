{ lib, pkgs }:

let
  mkTheme = import ./mk-theme.nix { inherit lib pkgs; };
  wallpaperImage =
    pkgs.runCommandLocal "hyprland-wallpaper.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 2560x1440 gradient:'#0f1118-#202534' \
          -fill 'rgba(143,180,255,0.22)' -draw 'circle 380,260 380,-120' \
          -fill 'rgba(143,180,255,0.12)' -draw 'circle 2180,1080 2180,760' \
          -fill 'rgba(232,236,243,0.05)' -draw 'rectangle 0,0 2559,1439' \
          "$out"
      '';
in
mkTheme {
  name = "midnight";
  colors = {
    background = "#0f1118";
    surface = "#171b24";
    surfaceAlt = "#202534";
    surfaceBright = "#2a3144";
    border = "#343c52";
    text = "#e8ecf3";
    muted = "#a7b0c0";
    primary = "#8fb4ff";
  };
  sansFont = "Fira Sans";
  monoFont = "FiraMono Nerd Font";
  surfaceOverlay = "rgba(23, 27, 36, 0.88)";
  wallpaper = wallpaperImage;
  terminalPalette = {
    normal = {
      black = "#171b24";
      red = "#c01c28";
      green = "#2ec27e";
      yellow = "#f5c211";
      blue = "#1e78e4";
      magenta = "#9841bb";
      cyan = "#0ab9dc";
      white = "#e8ecf3";
    };
    bright = {
      black = "#343c52";
      red = "#ed333b";
      green = "#57e389";
      yellow = "#f8e45c";
      blue = "#51a1ff";
      magenta = "#c061cb";
      cyan = "#4fd2fd";
      white = "#ffffff";
    };
  };
  extraPackages = with pkgs; [
    bibata-cursors
    fira
    materia-theme
    nerd-fonts.fira-mono
    papirus-icon-theme
  ];
}
