{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./wifi.nix
  ];

  system.stateVersion = "23.11";

  homelab = {
    homepage = {
      port = 8001;
      host = "home.dotboris.io";
    };

    reverseProxy.traefikDashboardHost = "traefik.dotboris.io";

    monitoring = {
      netdata = {
        port = 8002;
        host = "netdata.dotboris.io";
      };
      traefik.exporterPort = 8003;
    };

    feeds = {
      httpPort = 8004;
      host = "feeds.dotboris.io";
    };
  };

  sops = {
    defaultSopsFile = ./secrets.sops.yaml;

    # Generate an age key based on our SSH host key.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    gnupg.sshKeyPaths = []; # Turn off GPG key gen
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;

  networking = {
    hostName = "homelab";
    interfaces = {
      wlp0s29f7u8.ipv4.addresses = [
        {
          address = "10.0.42.2";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "10.0.42.1";
      interface = "wlp0s29f7u8";
    };
    nameservers = ["1.1.1.1"];
  };
}
