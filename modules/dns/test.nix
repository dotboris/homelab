{self, ...}: {
  flake.modules.nixosTest.dns = {pkgs, ...}: {
    defaults = {
      virtualisation.vlans = [1 2];
    };
    nodes = {
      server = {...}: {
        imports = [
          self.modules.nixos.dns
        ];
        homelab.dns = {
          enable = true;
          lanCidr = "192.168.1.0/24"; # eth1
          tailscaleCidr = "192.168.2.0/24"; # eth2
        };
      };
      client = {...}: {
        environment.systemPackages = [
          pkgs.busybox # for nslookup
        ];
      };
    };

    testScript = {nodes, ...}: let
      serverIp = interface: (pkgs.lib.head nodes.server.networking.interfaces.${interface}.ipv4.addresses).address;
    in ''
      start_all()
      server.wait_for_unit("coredns.service")
      server.wait_for_unit("network.target")
      client.wait_for_unit("network.target")

      with subtest("internal ips (lan)"):
        assert "10.0.42.2" in client.succeed("nslookup homelab.lan ${serverIp "eth1"}")
        assert "10.0.42.2" in client.succeed("nslookup home.dotboris.io ${serverIp "eth1"}")
        assert "10.0.42.3" in client.succeed("nslookup homelab-test.lan ${serverIp "eth1"}")
        assert "10.0.42.3" in client.succeed("nslookup home-test.dotboris.io ${serverIp "eth1"}")

      with subtest("internal ips (tailscale)"):
        assert "100.69.230.33" in client.succeed("nslookup homelab.lan ${serverIp "eth2"}")
        assert "100.69.230.33" in client.succeed("nslookup home.dotboris.io ${serverIp "eth2"}")
        assert "100.67.226.105" in client.succeed("nslookup homelab-test.lan ${serverIp "eth2"}")
        assert "100.67.226.105" in client.succeed("nslookup home-test.dotboris.io ${serverIp "eth2"}")

      with subtest("adblock (lan)"):
        assert "NXDOMAIN" in client.fail("nslookup doubleclick.net ${serverIp "eth1"}")

      with subtest("adblock (tailscale)"):
        assert "NXDOMAIN" in client.fail("nslookup doubleclick.net ${serverIp "eth2"}")
    '';
  };
}
