# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  pkgs,
  username,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./desktop.nix
    ./network.nix
    ./nix-settings.nix
    ./packages.nix
    ./vpn.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # The ESP is 487 MB and each generation puts a kernel and an initrd on it.
  # Without a limit the partition fills up and the next rebuild fails.
  boot.loader.systemd-boot.configurationLimit = 10;

  # This kernel does not support the Arrow Lake GPU (7d51) without a flag.
  # Without the driver, GNOME runs on simpledrm: it cannot turn off the
  # backlight on lock and it cannot find the real size of the screen.
  # Remove these parameters when the kernel supports 7d51 by default.
  boot.kernelParams = [
    "xe.force_probe=7d51"
    "i915.force_probe=!7d51"
  ];

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
    };
  };

  # polkit and sudo are on by default. Only hyprlock needs a line: it must
  # authenticate against PAM to unlock the screen.
  security.pam.services.hyprlock = { };

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
