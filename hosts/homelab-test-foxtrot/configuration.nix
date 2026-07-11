{
  config,
  moduleWithSystem,
  ...
}: {
  flake.hosts.homelab-test-foxtrot = {
    hostname = "homelab-test-foxtrot.lan";
    system = "x86_64-linux";
    module = moduleWithSystem ({self', ...}: {...}: {
      imports = [config.flake.modules.nixos.default];

      system.stateVersion = "25.05";

      homelab = {
        auth.enable = true;
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
        nextcloud.enable = true;
        search.enable = true;
        music.enable = true;
        files.enable = true;
        backups = {
          enable = true;
          destinations.local = {
            enable = true;
          };
          destinations.backblaze = {
            enable = false;
            region = "us-east-005";
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
    });
  };
}
