{ lib, pkgs }:

let
  mkTheme = import ./mk-theme.nix { inherit lib pkgs; };
in
mkTheme {
  name = "dank-material";
  colors = {
    background = "#141218";
    surface = "#211f24";
    surfaceAlt = "#2b292f";
    surfaceBright = "#36343a";
    border = "#948f99";
    text = "#d4d4d4";
    muted = "#808080";
    primary = "#d0bcff";
  };
  sansFont = "Inter";
  monoFont = "FiraCode Nerd Font";
  surfaceOverlay = "rgba(33, 31, 36, 0.84)";
  wallpaper = ../wallpapers/dank-material-rain-anime.jpg;
  terminalPalette = {
    normal = {
      black = "#1e1e1e";
      red = "#cd3131";
      green = "#0dbc79";
      yellow = "#c19c00";
      blue = "#2472c8";
      magenta = "#bc3fbc";
      cyan = "#11a8cd";
      white = "#d4d4d4";
    };
    bright = {
      black = "#666666";
      red = "#f14c4c";
      green = "#23d18b";
      yellow = "#f5f543";
      blue = "#3b8eea";
      magenta = "#d670d6";
      cyan = "#29b8db";
      white = "#e5e5e5";
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
