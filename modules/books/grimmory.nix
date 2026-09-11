{inputs, ...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    system,
    ...
  }: let
    cfg = config.homelab.books;
    grimmoryCfg = config.services.grimmory;
    vhost = config.homelab.reverseProxy.vhosts.books;
    secretsDir = "/var/lib/grimmory-secrets";
  in {
    imports = [
      # TODO: drop when merged and released
      "${inputs.nixpkgs-grimmory}/nixos/modules/services/web-apps/grimmory.nix"
    ];
    options.homelab.books = {
      enable = lib.mkEnableOption "Book management";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      nixpkgs.overlays = [
        # TODO: drop when merged and released
        (final: prev: let
          pkgsGrimmory = import inputs.nixpkgs-grimmory {
            inherit (final.stdenv.hostPlatform) system;
          };
        in {
          inherit (pkgsGrimmory) grimmory;
        })
      ];
      homelab = {
        auth.groups = ["books"];
        reverseProxy.vhosts.books = {};
        homepage.links = [
          {
            category = "services";
            title = "Books";
            icon = "sh-grimmory.svg";
            description = "Grimmory";
            urlVhost = "books";
          }
        ];
      };
      services = {
        grimmory = {
          inherit (cfg) port;
          enable = true;
          database.createLocally = true;
          environmentFile = "${secretsDir}/secrets.env";
        };
        traefik.dynamicConfigOptions.http = {
          routers.books = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "books";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.books = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
      systemd = {
        tmpfiles.rules = [
          "d ${secretsDir} 0700 ${grimmoryCfg.user} ${grimmoryCfg.group}"
        ];
        services.grimmory-db-password.preStart = lib.getExe (pkgs.writeShellApplication {
          name = "grimmory-generate-secrets";
          runtimeEnv = {
            inherit secretsDir;
            inherit (grimmoryCfg) user group;
          };
          runtimeInputs = [
            pkgs.openssl
          ];
          text = ''
            echo '[start] grimmory-generate-secrets'
            dbPasswordPath="$secretsDir/db-password"
            if [ ! -f "$dbPasswordPath" ]; then
              install \
                -o "$user" \
                -g "$group" \
                -m 0440 \
                /dev/null "$dbPasswordPath"
              openssl rand -hex 64 > "$dbPasswordPath"
              echo "Generated $dbPasswordPath"
            fi
            envPath="$secretsDir/secrets.env"
            echo "DATABASE_PASSWORD=$(cat "$dbPasswordPath")" > "$envPath"
            echo "Updated $envPath"
            echo '[stop] grimmory-generate-secrets'
          '';
        });
      };
    };
  };
}
