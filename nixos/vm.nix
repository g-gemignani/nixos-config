# The work VM on the company laptop: the desktop, the tools and the home of
# this machine, without its hardware, the games, Ollama and the VPN.
# It is installed from the NixOS ISO with ~/vms/transfer/install-vm.sh,
# which makes the two labeled partitions below.
{
  lib,
  modulesPath,
  pkgs,
  username,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./desktop.nix
    ./network.nix
    ./nix-settings.nix
    ./packages.nix
  ];

  # The VM has its own OVMF variable file, but systemd-boot also installs the
  # fallback loader, so the disk boots even with fresh variables.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # The VM disk is 97 GB, and seven generations filled it. Keep fewer.
  boot.loader.systemd-boot.configurationLimit = 3;
  nix.gc.dates = lib.mkForce "daily";
  nix.gc.options = lib.mkForce "--delete-older-than 3d";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  zramSwap.enable = true;

  # The SPICE agent lets the viewer send its window size, so QEMU and GNOME
  # resize the guest screen to fit. The clipboard still does not work on Wayland.
  services.spice-vdagentd.enable = true;
  # GNOME 50 skips the autostart file of the session agent, because it sets
  # X-GNOME-Autostart-Phase. Without the session agent the daemon never opens
  # the channel, so run the agent as a user service of the desktop session.
  systemd.user.services.spice-vdagent = {
    description = "SPICE session agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      Restart = "on-failure";
    };
  };

  # SSH from the host, for copy and paste in a host terminal. The SPICE
  # clipboard agent cannot work here, because GNOME runs on Wayland.
  #
  #   ssh -p 2222 gemignani@localhost
  # QEMU forwards only 127.0.0.1:2222 on the host, so nothing else reaches it.
  # network.nix binds sshd to loopback, which the forwarded traffic never hits.
  services.openssh = {
    listenAddresses = lib.mkForce [
      {
        addr = "0.0.0.0";
        port = 22;
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  networking.hostName = lib.mkForce "${username}-vm";

  users.users.${username} = {
    isNormalUser = true;
    # Fixed, because the installer copies ~/Coding in with this owner.
    uid = 1000;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    # Only for the first login. Change it with passwd straight away: this
    # value is readable in the nix store.
    initialPassword = "nixos";
    # The host user's key, for the SSH login above.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICthvEE++D3oEGLaO2t5/GkNeu9TDAr7x91nYyQrmCe/ twentyfour"
    ];
  };

  # The host shares ~/vms/transfer read-only, to copy files in.
  fileSystems."/mnt/transfer" = {
    device = "transfer";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "ro"
      "nofail"
    ];
  };

  system.stateVersion = "26.05";
}
