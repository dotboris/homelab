{config, ...}: {
  flake.hosts.homelab = {
    hostname = "homelab.lan";
    system = "x86_64-linux";
    module = {...}: {
      imports = [config.flake.modules.nixos.default];

      system.stateVersion = "25.05";

      homelab = {
        dns.enable = true;
        remote-access.enable = true;
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
        nextcloud = {
          enable = true;
          port = 8007;
        };
        search = {
          enable = true;
          port = 8008;
        };

        backups = {
          enable = true;
          destinations.local = {
            enable = true;
            checkAt = "*-*-01 00:00:00 America/Toronto";
          };
          destinations.backblaze = {
            enable = true;
            bucketName = "dotboris-homelab-backups";
            checkAt = "*-*-01 00:30:00 America/Toronto";
          };
          jobSchedules = {
            paperless = "01/6:00:00 America/Toronto";
            freshrss = "01/6:15:00 America/Toronto";
            github = "01:30:00 America/Toronto";
            nextcloud = "01:45:00 America/Toronto";
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
    };
  };
}
