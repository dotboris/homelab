{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.reverseProxy;
in {
  imports = [
    ./fastcgi-stopgap.nix
  ];

  options.homelab.reverseProxy = {
    traefikDashboardHost = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    services.traefik = {
      enable = true;

      staticConfigOptions = {
        entryPoints.web.address = ":80";
        entryPoints.websecure.address = ":443"; # TODO: full blown TLS

        api.dashboard = true;

        # Logs
        # accessLog = {};
        # log.level = "INFO";
      };

      dynamicConfigOptions = {
        http = {
          routers.traefikDashboard = {
            rule = "Host(`${cfg.traefikDashboardHost}`) && PathPrefix(`/dashboard`, `/api`)";
            service = "api@internal";
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
