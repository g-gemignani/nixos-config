# The only place a Surfshark region is named.
#
# nixos/vpn.nix turns each entry into a systemd unit, and home.nix turns each
# into vpn-start-<key>, vpn-stop-<key> and vpn-status-<key> shell helpers.
# Adding a region means adding its .ovpn file and one entry here.
{
  it = {
    name = "IT";
    ovpn = ./it-mil.prod.surfshark.com_udp.ovpn;
  };
  us = {
    name = "US";
    ovpn = ./us-nyc.prod.surfshark.com_udp.ovpn;
  };
}
