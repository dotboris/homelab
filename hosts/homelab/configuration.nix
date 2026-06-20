{
  config,
  inputs,
  ...
}: {
  flake.hosts.homelab = {
    hostname = "homelab.lan";
    system = "x86_64-linux";
    module = {...}: {
      imports = [
        inputs.nixos-hardware.nixosModules.dell-optiplex-3050
        config.flake.modules.nixos.default
      ];

      system.stateVersion = "25.05";

      homelab = {
        dns.enable = true;
        remote-access.enable = true;
        reverseProxy = {
          baseDomain = "dotboris.io";
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
            checkAt = "*-*-01 00:00:00 America/Toronto";
          };
          destinations.backblaze = {
            enable = true;
            bucketName = "dotboris-homelab-backups";
            checkAt = "*-*-01 00:30:00 America/Toronto";
          };
          jobs = {
            paperless.schedule = "01/6:00:00 America/Toronto"; # 4x a day
            freshrss.schedule = "01/6:15:00 America/Toronto"; # 4x a day
            github.schedule = "01:30:00 America/Toronto"; # daily
            nextcloud.schedule = "01:45:00 America/Toronto"; # daily
            music.schedule = "02:00:00 America/Toronto"; # daily
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
        efi.canTouchEfiVariables = true;
        grub = {
          enable = true; # Use the GRUB 2 boot loader.
          efiSupport = true;
        };
      };

      networking = {
        hostName = "homelab";
        useDHCP = false;
        interfaces = {
          enp1s0.ipv4.addresses = [
            {
              address = "10.0.42.2";
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
