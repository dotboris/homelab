{config, ...}: {
  flake.hosts.homelab-test = {
    hostname = "homelab-test.lan";
    system = "x86_64-linux";
    module = {...}: {
      imports = [config.flake.modules.nixos.default];

      system.stateVersion = "25.05";

      homelab = {
        auth.enable = true;
        dns.enable = true;
        mail.enable = true;
        remote-access.enable = true;
        reverseProxy = {
          baseDomain = "dotboris.io";
          vhostSuffix = "-test";
          tls.acme.enable = true;
        };
        nextcloud.enable = true;
        search.enable = true;
        music.enable = true;
        files.enable = true;
        backups = {
          enable = true;
          destinations.local.enable = true;
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
      };
    };
  };
}
