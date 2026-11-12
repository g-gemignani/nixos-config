# The root partition is LUKS2. The UUID of the LUKS header is set here first
# and passed to cryptsetup when the partition is encrypted, so this file can
# exist before the encryption.
{ lib, ... }:

{
  # The VM shows the disk as virtio; the laptop at home shows it as USB.
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
  ];

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/63df752b-4025-47a0-a8df-5bfd8d4ce66b";
    allowDiscards = true;
  };

  # systemd mounted the ESP on its own only when systemd-boot on this disk
  # started the machine. State it, so a rebuild always finds it.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5617-694C";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # A plain swap partition keeps memory pages readable on the disk. This one
  # gets a new random key at every boot. Hibernation does not work with it.
  swapDevices = lib.mkForce [
    {
      device = "/dev/disk/by-partuuid/18bcd559-d5c5-48b2-af9b-1036bd5cebea";
      randomEncryption.enable = true;
    }
  ];
}
