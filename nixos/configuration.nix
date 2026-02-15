# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "${username}"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = false;
  # OR
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    loadModels = [ "gemma:2b" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    "${username}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ]; # Enable ‘sudo’ for the user.
      packages = with pkgs; [
        tree
      ];
      # surfshark user service declared globally below
    };
  };

  security.sudo.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    p7zip
    zip
    unzip
    wget
    git
    gnupg
    pinentry-curses
    htop
    silver-searcher
    google-chrome
    nix-search-cli
    nixfmt
    flameshot
    nix-direnv
    # gaming
    lutris # set wine-ge-proton as runnner for Battle.net
    wine
    winetricks
    cabextract
    mesa
    vulkan-loader
    vulkan-tools
    wineWow64Packages.staging
    dxvk
    gamemode
    # coding
    python3
    uv
    poetry
    cargo
    gcc
    pkg-config
    ollama
    # VPN support: OpenVPN + NetworkManager plugins
    openvpn
    home-manager
    networkmanager-openvpn
    networkmanager
    transmission_4-qt
    # sops for encrypting/decrypting secrets stored in the repo
    sops
    gawk
    util-linux
    procps
    lsof
    gnused
    # office
    onlyoffice-desktopeditors
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  programs.gamemode.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.download-buffer-size = 100000000;
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://ros.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  sops.secrets.vpn_auth = {
    sopsFile = ../secrets/vpn_secrets.yaml; # Path to your encrypted file
    owner = "root";
  };

  # This runs as root and uses /etc/openvpn/auth.txt produced by the activation script.
  systemd.services.surfshark-openvpn-it = {
    description = "Surfshark OpenVPN (system) - IT";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network-online.target"
      "sops-nix.service"
    ];

    serviceConfig = {
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      Type = "simple";
      ExecStart = "${pkgs.openvpn}/bin/openvpn --config ${../vpn/it-mil.prod.surfshark.com_udp.ovpn} --auth-user-pass ${config.sops.secrets.vpn_auth.path}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.surfshark-openvpn-us = {
    description = "Surfshark OpenVPN (system) - US";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network-online.target"
      "sops-nix.service"
    ];

    serviceConfig = {
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      Type = "simple";

      # We point directly to the decrypted sops file
      ExecStart = "${pkgs.openvpn}/bin/openvpn --config ${../vpn/us-nyc.prod.surfshark.com_udp.ovpn} --auth-user-pass ${config.sops.secrets.vpn_auth.path}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # (surfshark user unit declared above)

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}
