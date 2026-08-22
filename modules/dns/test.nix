{self, ...}: {
  flake.modules.nixosTest.dns = {pkgs, ...}: {
    defaults = {
      virtualisation.vlans = [1 2];
    };
    containers = {
      server = {...}: {
        imports = [
          self.modules.nixos.dns
        ];
        homelab.dns = {
          enable = true;
          lanCidr = "192.168.1.0/24"; # eth1
          tailscaleCidr = "192.168.2.0/24"; # eth2
          extraHosts = {
            "local-only.lan".lan = "192.168.0.42";
            "both.lan" = {
              lan = "192.168.0.69";
              tailscale = "100.0.0.69";
            };
          };
        };
      };
      client = {...}: {
        environment.systemPackages = [
          pkgs.busybox # for nslookup
        ];
      };
    };

    testScript = {containers, ...}: let
      serverIp = interface: (pkgs.lib.head containers.server.networking.interfaces.${interface}.ipv4.addresses).address;
    in
      # python
      ''
        start_all()
        server.wait_for_unit("coredns.service")
        server.wait_for_unit("network.target")
        client.wait_for_unit("network.target")

        with subtest("internal ips (lan)"):
          t.assertIn("10.0.42.2", client.succeed("nslookup homelab.lan ${serverIp "eth1"}"))
          t.assertIn("10.0.42.2", client.succeed("nslookup home.dotboris.io ${serverIp "eth1"}"))
          t.assertIn("10.0.42.3", client.succeed("nslookup homelab-test.lan ${serverIp "eth1"}"))
          t.assertIn("10.0.42.3", client.succeed("nslookup home-test.dotboris.io ${serverIp "eth1"}"))
          t.assertIn("192.168.0.42", client.succeed("nslookup local-only.lan ${serverIp "eth1"}"))
          t.assertIn("192.168.0.69", client.succeed("nslookup both.lan ${serverIp "eth1"}"))

        with subtest("internal ips (tailscale)"):
          t.assertIn("100.69.230.33", client.succeed("nslookup homelab.lan ${serverIp "eth2"}"))
          t.assertIn("100.69.230.33", client.succeed("nslookup home.dotboris.io ${serverIp "eth2"}"))
          t.assertIn("100.67.226.105", client.succeed("nslookup homelab-test.lan ${serverIp "eth2"}"))
          t.assertIn("100.67.226.105", client.succeed("nslookup home-test.dotboris.io ${serverIp "eth2"}"))
          t.assertIn("100.0.0.69", client.succeed("nslookup both.lan ${serverIp "eth2"}"))

        with subtest("adblock (lan)"):
          assert "NXDOMAIN" in client.fail("nslookup doubleclick.net ${serverIp "eth1"}")

        with subtest("adblock (tailscale)"):
          assert "NXDOMAIN" in client.fail("nslookup doubleclick.net ${serverIp "eth2"}")
      '';
  };
}
