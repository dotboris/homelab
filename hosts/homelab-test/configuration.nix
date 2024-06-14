{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.11";

  homelab = {
    homepage = {
      port = 8001;
      host = "home-test.dotboris.io";
    };

    reverseProxy = {
      traefikDashboardHost = "traefik-test.dotboris.io";
      tls.acme.enable = true;
    };

    monitoring = {
      netdata = {
        port = 8002;
        host = "netdata-test.dotboris.io";
      };
      traefik.exporterPort = 8003;
    };

    feeds = {
      httpPort = 8004;
      host = "feeds-test.dotboris.io";
    };

    documents-archive = {
      port = 8005;
      host = "archive-test.dotboris.io";
    };
  };

  sops = {
    defaultSopsFile = ./secrets.sops.yaml;

    # Generate an age key based on our SSH host key.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    gnupg.sshKeyPaths = []; # Turn off GPG key gen
  };

  boot.loader = {
    grub.enable = true;
    timeout = 0; # Skip the menu
  };

  networking = {
    hostName = "homelab-test";
    interfaces = {
      enp1s0.ipv4.addresses = [
        {
          address = "10.0.42.3";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "10.0.42.1";
      interface = "enp1s0";
    };
    nameservers = ["1.1.1.1"];
  };
}
