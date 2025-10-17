{config, ...}: {
  flake.hosts.homelab-test-foxtrot = {
    ip = "192.168.122.3";
    system = "x86_64-linux";
    module = {...}: {
      imports = [config.flake.modules.nixos.default];

      system.stateVersion = "25.05";

      homelab = {
        dns = {
          enable = true;
          lanCidr = "192.168.122.0/24";
        };
        remote-access.enable = true;
        reverseProxy = {
          baseDomain = "dotboris.io";
          vhostSuffix = "-test-foxtrot";
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
        nextcloud = {
          enable = true;
          port = 8007;
        };

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
        hostName = "homelab-test-foxtrot";
        useDHCP = false;
        interfaces = {
          enp1s0.ipv4.addresses = [
            {
              address = "192.168.122.3";
              prefixLength = 24;
            }
          ];
        };
        defaultGateway = {
          address = "192.168.122.1";
          interface = "enp1s0";
        };
      };
    };
  };
}
