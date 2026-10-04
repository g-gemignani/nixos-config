# KeePassXC, with the database synced from Dropbox by Maestral.
#
# Maestral is an open-source Dropbox client. Link the account once with
# `maestral auth link`, then the user service below keeps ~/Dropbox in sync
# in the GNOME and the Hyprland session alike.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    keepassxc
    maestral
  ];

  systemd.user.services.maestral = {
    Unit = {
      Description = "Maestral Dropbox sync";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      # Fails until the account is linked. Retry slowly instead of giving up.
      Restart = "on-failure";
      RestartSec = 60;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
