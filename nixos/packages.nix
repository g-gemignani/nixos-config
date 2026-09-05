# What is installed system-wide, plus the modules that wrap a package.
{ pkgs, ... }:

{
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    p7zip
    zip
    unzip
    wget
    git
    gh
    glab
    pinentry-curses
    htop
    silver-searcher
    google-chrome
    flameshot
    dnsutils
    rar
    unar
    # gaming
    lutris # set wine-ge-proton as runner for Battle.net
    wine
    winetricks
    cabextract
    vulkan-tools
    wineWow64Packages.staging
    # coding
    python3
    uv
    poetry
    cargo
    gcc
    pkg-config
    ollama
    code-cursor
    claude-code
    # VPN support: OpenVPN + NetworkManager plugins
    openvpn
    networkmanager-openvpn
    networkmanagerapplet
    transmission_4-qt
    wdisplays
    blueman
    # sops for encrypting/decrypting secrets stored in the repo
    sops
    lsof
    # office
    onlyoffice-desktopeditors
    xournalpp
  ];

  # enable32Bit is what wine and steam need. The mesa drivers come with the
  # option: hardware.graphics.package already defaults to pkgs.mesa.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
