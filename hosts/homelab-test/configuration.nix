{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.11";

  homelab = {
    dns.enable = true;
    reverseProxy = {
      baseDomain = "dotboris.io";
      vhostSuffix = "-test";
      tls.acme.enable = true;
    };
    homepage.port = 8001;
    monitoring = {
      netdata.port = 8002;
      traefik.exporterPort = 8003;
      ntfy.port = 8006;
    };
    feeds.httpPort = 8004;
    documents-archive.port = 8005;

    backups = {
      enable = true;
      backends.local.enable = true;
      backends.backblaze = {
        enable = true;
        bucketName = "dotboris-homelab-test-backups";
      };
      github = {
        enable = true;
        cloneWiki = true;
        skipArchived = true;
        skipForks = true;
        cloneType = "user";
        githubOrg = "dotboris";
        appId = "1030841";
        installationId = "56188691";
      };
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
    useDHCP = false;
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
