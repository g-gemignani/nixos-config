# The only place a tunnel is named.
#
# nixos/vpn.nix turns each entry into a systemd unit, and home.nix turns each
# into vpn-start-<key>, vpn-stop-<key> and vpn-status-<key> shell helpers.
# Adding a tunnel means adding its profile and one entry here.
#
# Per entry:
#   name          Text for the unit description.
#   ovpn          Path to a .ovpn file in this directory. Public settings only:
#                 the nix store is world readable.
#   ovpnSecret    Name of a sops secret that holds the whole .ovpn file. Use
#                 this instead of ovpn when the profile carries a private key.
#   authUserPass  Send the sops username and password. Default true.
#                 Set it to false for a profile that authenticates by
#                 certificate.
#   killSwitch    Arm the kill switch with the tunnel. Default true.
{
  it = {
    name = "IT";
    ovpn = ./it-mil.prod.surfshark.com_udp.ovpn;
  };
  us = {
    name = "US";
    ovpn = ./us-nyc.prod.surfshark.com_udp.ovpn;
  };

  # Azure Point-to-Site work tunnel, rebuilt from the NetworkManager profile
  # of the old Ubuntu install. It authenticates with a client certificate,
  # so it needs no username and password.
  #
  # The kill switch stays off for two reasons. The gateway listens on TCP
  # 443, and the kill switch lets out only UDP 1194, so it would reject the
  # handshake. And this is a split tunnel: the office routes come from the
  # server and normal traffic keeps the local default route. A kill switch
  # would block that traffic, which is not what a work tunnel is for.
  "24" = {
    name = "24 (Azure)";
    ovpnSecret = "vpn_24_ovpn";
    authUserPass = false;
    killSwitch = false;
  };
}
