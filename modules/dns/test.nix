{pkgs, ...}: {
  name = "dns";
  nodes = {
    server = {...}: {
      imports = [./default.nix];
      homelab.dns.enable = true;
      homelab.dns.lanCidr = "192.168.1.0/24";
    };
    client = {...}: {
      environment.systemPackages = [
        pkgs.busybox # for nslookup
      ];
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("coredns.service")

    # Internal IPs
    assert "10.0.42.2" in client.succeed("nslookup homelab.lan server")
    assert "10.0.42.2" in client.succeed("nslookup home.dotboris.io server")
    assert "10.0.42.3" in client.succeed("nslookup homelab-test.lan server")
    assert "10.0.42.3" in client.succeed("nslookup home-test.dotboris.io server")

    # adblock
    assert "NXDOMAIN" in client.fail("nslookup doubleclick.net server")
  '';
}
