{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.reverseProxy.tls.acme;
    acmeStoreRelDir = "traefik-acme";
    acmeStoreDir = "/var/lib/${acmeStoreRelDir}";
    acmeStoreFile = "${acmeStoreDir}/acme.json";
  in {
    options.homelab.reverseProxy.tls.acme = {
      enable = lib.mkEnableOption "reverse proxy acme";
    };

    config = lib.mkIf cfg.enable {
      homelab.reverseProxy.tls.value = {
        certResolver = "main";
      };

      systemd.services."create-traefik-acme-json" = {
        description = "Create the acme.json store file for traefik";

        script = ''
          touch "$STATE_DIRECTORY/acme.json"
          chmod 600 "$STATE_DIRECTORY/acme.json"
        '';

        wantedBy = ["traefik.service"];

        unitConfig = {
          Before = ["traefik.service"];
          ConditionPathExists = "!${acmeStoreFile}";
        };

        serviceConfig = {
          User = "traefik";
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = acmeStoreRelDir;
        };
      };

      sops = {
        secrets = {
          "acme/cloudflare/zone-api-token" = {};
          "acme/cloudflare/dns-api-token" = {};
        };
        templates."traefik-acme.env".content = ''
          CLOUDFLARE_ZONE_API_TOKEN=${config.sops.placeholder."acme/cloudflare/zone-api-token"}
          CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."acme/cloudflare/dns-api-token"}
        '';
      };

      services.traefik = {
        environmentFiles = [
          config.sops.templates."traefik-acme.env".path
        ];
        staticConfigOptions = {
          certificatesResolvers.main.acme = {
            # Remember to empty `acme.json` when switching from stg to prod or vise versa
            # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
            email = "beraboris+homelab-acme@gmail.com";
            storage = acmeStoreFile;
            dnsChallenge = {
              provider = "cloudflare";
              delayBeforeCheck = 0;
            };
          };
        };
      };
    };
  };
}
