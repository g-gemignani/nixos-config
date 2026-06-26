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
  networking.networkmanager.dns = "systemd-resolved";

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

  # Enable the X11 windowing system (required base even for Wayland/Hyprland).
  services.xserver.enable = true;

  # Expose both GNOME and Hyprland in the greeter.
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "gnome";
  services.desktopManager.gnome.enable = true;

  # Enable Hyprland.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true; # For X11 app compatibility.
  };

  # Keep the greeter and Wayland session on the same keyboard layouts.
  services.xserver.xkb.layout = "de,us";
  services.xserver.xkb.options = "grp:ctrl_space_toggle";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound via PipeWire.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.resolved.enable = true;

  # Enable touchpad support (enabled by default in most desktopManagers).
  services.libinput.enable = true;

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      fira
      liberation_ttf
      nerd-fonts.fira-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      antialias = true;
      defaultFonts = {
        sansSerif = [
          "Fira Sans"
          "Noto Sans"
        ];
        serif = [ "Noto Serif" ];
        monospace = [
          "FiraMono Nerd Font"
          "Noto Sans Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    loadModels = [ "gemma:2b" ];
  };

  # Keep generic Wayland app support enabled across desktop sessions.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Portals are required for screen sharing, file pickers, and browser integration.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users = {
    "${username}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ]; # Enable 'sudo' for the user.
      packages = with pkgs; [
        tree
      ];
      # surfshark user service declared globally below
    };
  };

  security.polkit.enable = true;
  security.sudo.enable = true;
  security.pam.services.hyprlock = { };

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
    alacritty
    dnsutils
    rar
    unar
    # gaming
    lutris # set wine-ge-proton as runner for Battle.net
    wine
    winetricks
    cabextract
    mesa
    vulkan-loader
    vulkan-tools
    wineWow64Packages.staging
    dxvk
    gamemode
    steam
    # coding
    python3
    uv
    poetry
    cargo
    gcc
    pkg-config
    ollama
    github-copilot-cli
    # VPN support: OpenVPN + NetworkManager plugins
    openvpn
    home-manager
    networkmanager-openvpn
    networkmanager
    networkmanagerapplet
    transmission_4-qt
    gnome-control-center
    gnome-calculator
    gnome-settings-daemon
    wdisplays
    blueman
    # sops for encrypting/decrypting secrets stored in the repo
    sops
    gawk
    util-linux
    procps
    lsof
    gnused
    # office
    onlyoffice-desktopeditors
    xournalpp
    # Wayland utilities
    xdg-desktop-portal-hyprland
    xdg-utils
    wl-clipboard
    waybar
    dunst
    wofi
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
  nix.settings.download-buffer-size = 524288000;
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

  systemd.services =
    let
      updateSystemdResolved = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
      vpnDependencies = [
        "network-online.target"
        "sops-nix.service"
        "systemd-resolved.service"
      ];

      mkSurfsharkService = region: ovpnFile: {
        description = "Surfshark OpenVPN (system) - ${region}";
        after = vpnDependencies;
        wants = vpnDependencies;

        serviceConfig = {
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          ExecStart = "${pkgs.openvpn}/bin/openvpn --config ${ovpnFile} --auth-user-pass ${config.sops.secrets.vpn_auth.path} --script-security 2 --up ${updateSystemdResolved} --up-restart --down ${updateSystemdResolved} --down-pre";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          Restart = "on-failure";
          RestartSec = 5;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          Type = "simple";
          UMask = "0077";
        };
      };
    in
    {
      surfshark-openvpn-it = mkSurfsharkService "IT" ../vpn/it-mil.prod.surfshark.com_udp.ovpn;
      surfshark-openvpn-us = mkSurfsharkService "US" ../vpn/us-nyc.prod.surfshark.com_udp.ovpn;
    };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

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
