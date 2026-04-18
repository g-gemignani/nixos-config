{ lib, pkgs }:

let
  mkTheme = import ./mk-theme.nix { inherit lib pkgs; };
  wallpaperImage =
    pkgs.runCommandLocal "hyprland-wallpaper-simp1e-late-night.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 2560x1440 gradient:'#0b0f16-#1a1f34' \
          -fill 'rgba(122,162,247,0.20)' -draw 'circle 2120,260 2120,20' \
          -fill 'rgba(186,154,255,0.14)' -draw 'circle 420,1120 420,820' \
          -fill 'rgba(255,255,255,0.04)' -draw 'rectangle 0,0 2559,1439' \
          "$out"
      '';
in
mkTheme {
  name = "simp1e-late-night";
  colors = {
    background = "#0b0f16";
    surface = "#141b24";
    surfaceAlt = "#1b2330";
    surfaceBright = "#263246";
    border = "#3a4964";
    text = "#dfe7f5";
    muted = "#97a4bb";
    primary = "#7aa2f7";
  };
  sansFont = "Fira Sans";
  monoFont = "FiraMono Nerd Font";
  surfaceOverlay = "rgba(20, 27, 36, 0.86)";
  wallpaper = wallpaperImage;
  terminalPalette = {
    normal = {
      black = "#141b24";
      red = "#f7768e";
      green = "#9ece6a";
      yellow = "#e0af68";
      blue = "#7aa2f7";
      magenta = "#bb9af7";
      cyan = "#7dcfff";
      white = "#dfe7f5";
    };
    bright = {
      black = "#3a4964";
      red = "#ff899d";
      green = "#b9f27c";
      yellow = "#f3c97f";
      blue = "#8db4ff";
      magenta = "#cfb2ff";
      cyan = "#a4daff";
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
