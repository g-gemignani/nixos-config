# Hostname, DHCP, DNS, the firewall, and the one daemon allowed to listen.
{ username, ... }:

{
  networking.hostName = "${username}"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved.enable = true;

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

  # GNOME pulls in avahi, which opens UDP 5353 for mDNS. Nothing here uses
  # it: printing is off, nssmdns4 is false so .local names never reach name
  # resolution, and publish.enable is false so we advertise nothing. The
  # daemon stays for GNOME's sake; only the inbound port closes. Set this
  # back to true if network printer or cast discovery is ever wanted.
  services.avahi.openFirewall = false;
  # If something ever does need to listen, open just that port here rather
  # than turning the firewall off:
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
}
