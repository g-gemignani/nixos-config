# The work VM on the company laptop: the desktop, the tools and the home of
# this machine, without its hardware, the games, Ollama and the VPN.
# It is installed from the NixOS ISO with ~/vms/transfer/install-vm.sh,
# which makes the two labeled partitions below.
{
  lib,
  modulesPath,
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
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICthvEE++D3oEGLaO2t5/GkNeu9TDAr7x91nYyQrmCe/ twentyfour" ];
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
