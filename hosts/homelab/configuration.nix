{config, ...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
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

  sops.secrets."networking/wireless/env" = {};
  networking = {
    hostName = "homelab";
    wireless = {
      enable = true;
      environmentFile = config.sops.secrets."networking/wireless/env".path;
      networks = {
        romeo = {psk = "@romeo_psk@";};
      };
    };
    interfaces = {
      wlan0.ipv4.addresses = [
        {
          address = "10.0.42.2";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.0.42.1";
    nameservers = ["1.1.1.1"];
  };
}
