# Surfshark tunnels and the kill switch that stops them leaking.
# Regions come from ../vpn/regions.nix, which also drives the shell helpers.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  sops.secrets.vpn_auth = {
    sopsFile = ../secrets/vpn_secrets.yaml; # Path to your encrypted file
    owner = "root";
  };

  systemd.services =
    let
      regions = import ../vpn/regions.nix;
      updateSystemdResolved = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
      # No sops unit here: sops-nix writes /run/secrets from an activation
      # script, which has already run by the time anything can start these.
      # "sops-nix.service" used to be listed and does not exist, so systemd
      # ignored it. The ordering it implied was never real.
      vpnDependencies = [
        "network-online.target"
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
        conflicts = conflictsWith;

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

    }
    // lib.mapAttrs' (
      key: region:
      lib.nameValuePair "surfshark-openvpn-${key}" (
        mkSurfsharkService region.name (map (other: "surfshark-openvpn-${other}.service") (
          builtins.filter (k: k != key) (builtins.attrNames regions)
        )) region.ovpn
      )
    ) regions
    // {
    };
}
