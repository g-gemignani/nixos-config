# Games, the torrent client and the local LLM. They stay on this machine and
# do not go into the work VM.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lutris # set wine-ge-proton as runner for Battle.net
    winetricks
    cabextract
    vulkan-tools
    wineWow64Packages.staging
    transmission_4-qt
  ];

  # enable32Bit is what wine and steam need. The mesa drivers come with the
  # option: hardware.graphics.package already defaults to pkgs.mesa.
  hardware.graphics.enable32Bit = true;

  programs.gamemode.enable = true;

  # The module, not just pkgs.steam. It is what brings the controller udev
  # rules and the 32-bit FHS wrapper. It opens no ports: remotePlay and
  # dedicatedServer both default to openFirewall = false.
  programs.steam.enable = true;

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    loadModels = [ "gemma:2b" ];
  };
}
