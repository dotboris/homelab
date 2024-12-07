{...}: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.11";

  homelab = {
    reverseProxy = {
      baseDomain = "dotboris.io";
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
        bucketName = "dotboris-homelab-backups";
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
      locations = {
        paperless.cron = "0 */6 * * *";
        freshrss.cron = "0 */6 * * *";
        github.cron = "0 1 * * *";
      };
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
    useDHCP = false;
    interfaces = {
      enp2s0.ipv4.addresses = [
        {
          address = "10.0.42.2";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "10.0.42.1";
      interface = "enp2s0";
    };
  };
}
