{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.reverseProxy;
in {
  imports = [
    ./fastcgi-stopgap.nix
    ./acme.nix
    ./tls-snakeoil.nix
  ];

  options.homelab.reverseProxy = {
    traefikDashboardHost = lib.mkOption {
      type = lib.types.str;
    };
    tls.value = lib.mkOption {
      type = lib.types.attrs;
    };
  };

  config = {
    services.traefik = {
      enable = true;

      staticConfigOptions = {
        entryPoints.web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        entryPoints.websecure.address = ":443";

        api.dashboard = true;

        # Logs
        accessLog = {};
        log.level = "INFO";
      };

      dynamicConfigOptions = {
        http = {
          routers.traefikDashboard = {
            rule = "Host(`${cfg.traefikDashboardHost}`) && PathPrefix(`/dashboard`, `/api`)";
            service = "api@internal";
            tls = cfg.tls.value;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
