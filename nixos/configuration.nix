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
      xdg-desktop-portal-gnome
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
    gh
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
    mesa
    vulkan-loader
    vulkan-tools
    wineWow64Packages.staging
    dxvk
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
    home-manager
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
    # Wayland utilities
    dunst
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  programs.gamemode.enable = true;

  # The module, not just pkgs.steam. It is what brings the controller udev
  # rules and the 32-bit FHS wrapper. It opens no ports: remotePlay and
  # dedicatedServer both default to openFirewall = false.
  programs.steam.enable = true;

  # The closure is about 18 GB. Left to a prompt inside update-all, garbage
  # collection only happens when someone remembers to say yes.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

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

      # -w makes every call wait for /run/xtables.lock. Without it a call that
      # collides with the NixOS firewall (which does pass -w) fails on the
      # spot, and a half-installed rule set is how you lose the network.
      iptables = "${pkgs.iptables}/bin/iptables -w 5";
      ip6tables = "${pkgs.iptables}/bin/ip6tables -w 5";

      # Kill switch. While a tunnel is up, the only traffic allowed out is the
      # tunnel itself, the local network, and the handshake that brings the
      # tunnel back. Everything else is rejected, so a tunnel that drops
      # cannot leak traffic in the clear.
      #
      # It is its own unit, not a pair of hooks on the VPN units, for two
      # reasons. One chain has one owner, so two VPN units can never race each
      # other into tearing down a chain the other still needs. And it stays up
      # across an openvpn restart, so the RestartSec window is not a hole.
      #
      # Recovery: stop the VPN unit, and this stops with it. Failing that,
      # `sudo iptables -w 5 -D OUTPUT -j SURFSHARK-KILL`. The rules are never
      # persisted, so a reboot always clears them.
      killSwitchUp = pkgs.writeShellScript "surfshark-killswitch-up" ''
        set -eu

        ${iptables} -N SURFSHARK-KILL 2>/dev/null || true
        ${iptables} -F SURFSHARK-KILL
        ${iptables} -A SURFSHARK-KILL -o lo -j RETURN
        ${iptables} -A SURFSHARK-KILL -o tun+ -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 127.0.0.0/8 -j RETURN
        # Every private range, plus carrier NAT, which is what a phone
        # hotspot hands out. Leaving it out strands the machine on tethering.
        ${iptables} -A SURFSHARK-KILL -d 10.0.0.0/8 -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 172.16.0.0/12 -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 192.168.0.0/16 -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 169.254.0.0/16 -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 100.64.0.0/10 -j RETURN
        # Local discovery: mDNS, SSDP, printers, casting.
        ${iptables} -A SURFSHARK-KILL -d 224.0.0.0/4 -j RETURN
        ${iptables} -A SURFSHARK-KILL -d 255.255.255.255/32 -j RETURN
        # DHCP renewal, and the handshake to the VPN server.
        ${iptables} -A SURFSHARK-KILL -p udp --dport 67:68 -j RETURN
        ${iptables} -A SURFSHARK-KILL -p udp --dport 1194 -j RETURN
        ${iptables} -A SURFSHARK-KILL -j REJECT --reject-with icmp-admin-prohibited
        ${iptables} -C OUTPUT -j SURFSHARK-KILL 2>/dev/null \
          || ${iptables} -I OUTPUT 1 -j SURFSHARK-KILL

        # These Surfshark endpoints are IPv4 only, so IPv6 has no tunnel to
        # travel through. Global v6 is rejected, which is the leak that bites
        # most often. Link-local, unique-local and multicast stay open: this
        # router hands out a unique-local resolver, and neighbour discovery
        # runs over multicast. Blocking those breaks DNS and the v6 route.
        ${ip6tables} -N SURFSHARK-KILL 2>/dev/null || true
        ${ip6tables} -F SURFSHARK-KILL
        ${ip6tables} -A SURFSHARK-KILL -o lo -j RETURN
        ${ip6tables} -A SURFSHARK-KILL -d ::1/128 -j RETURN
        ${ip6tables} -A SURFSHARK-KILL -d fe80::/10 -j RETURN
        ${ip6tables} -A SURFSHARK-KILL -d fc00::/7 -j RETURN
        ${ip6tables} -A SURFSHARK-KILL -d ff00::/8 -j RETURN
        ${ip6tables} -A SURFSHARK-KILL -j REJECT --reject-with adm-prohibited
        ${ip6tables} -C OUTPUT -j SURFSHARK-KILL 2>/dev/null \
          || ${ip6tables} -I OUTPUT 1 -j SURFSHARK-KILL
      '';

      # Never fails: an error here would leave the machine with no way out.
      # It does check its own work, though. Silent failure is how a stuck
      # chain survives a stop that reported success.
      killSwitchDown = pkgs.writeShellScript "surfshark-killswitch-down" ''
        ${iptables} -D OUTPUT -j SURFSHARK-KILL 2>/dev/null || true
        ${iptables} -F SURFSHARK-KILL 2>/dev/null || true
        ${iptables} -X SURFSHARK-KILL 2>/dev/null || true
        ${ip6tables} -D OUTPUT -j SURFSHARK-KILL 2>/dev/null || true
        ${ip6tables} -F SURFSHARK-KILL 2>/dev/null || true
        ${ip6tables} -X SURFSHARK-KILL 2>/dev/null || true

        if ${iptables} -C OUTPUT -j SURFSHARK-KILL 2>/dev/null; then
          echo "kill switch STILL ACTIVE on IPv4. Run: iptables -w 5 -D OUTPUT -j SURFSHARK-KILL" >&2
        fi
        if ${ip6tables} -C OUTPUT -j SURFSHARK-KILL 2>/dev/null; then
          echo "kill switch STILL ACTIVE on IPv6. Run: ip6tables -w 5 -D OUTPUT -j SURFSHARK-KILL" >&2
        fi
        exit 0
      '';

      mkSurfsharkService = region: conflictsWith: ovpnFile: {
        description = "Surfshark OpenVPN (system) - ${region}";
        wants = vpnDependencies;

        # The kill switch must be armed before openvpn sends its first packet,
        # and it stops on its own once no tunnel needs it.
        requires = [ "surfshark-killswitch.service" ];
        after = vpnDependencies ++ [ "surfshark-killswitch.service" ];

        # Two tunnels at once fight over the default route.
        conflicts = [ conflictsWith ];

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
      surfshark-killswitch = {
        description = "Surfshark kill switch (blocks traffic outside the tunnel)";
        # Goes away by itself when the last VPN unit stops.
        unitConfig.StopWhenUnneeded = true;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = killSwitchUp;
          ExecStop = killSwitchDown;
          AmbientCapabilities = "CAP_NET_ADMIN";
          CapabilityBoundingSet = "CAP_NET_ADMIN";
        };
      };

      surfshark-openvpn-it =
        mkSurfsharkService "IT" "surfshark-openvpn-us.service"
          ../vpn/it-mil.prod.surfshark.com_udp.ovpn;
      surfshark-openvpn-us =
        mkSurfsharkService "US" "surfshark-openvpn-it.service"
          ../vpn/us-nyc.prod.surfshark.com_udp.ovpn;
    };

  # Nothing on this laptop needs to accept an inbound connection. sshd is the
  # one exception, and not because anyone logs in: sops-nix derives the host
  # age key in .sops.yaml from the ssh host key, so without the daemon the
  # machine can no longer decrypt secrets/vpn_secrets.yaml.
  #
  # So keep it, and make it unreachable. openFirewall defaults to true, which
  # would open port 22 the moment the firewall came on. It binds to loopback
  # as well, so nothing external reaches it even if the firewall is down.
  services.openssh = {
    enable = true;
    openFirewall = false;
    listenAddresses = [
      {
        addr = "127.0.0.1";
        port = 22;
      }
    ];
  };

  networking.firewall.enable = true;
  # If something ever does need to listen, open just that port here rather
  # than turning the firewall off:
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

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
