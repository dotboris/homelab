{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.feeds;
  user = "freshrss";
in {
  options.homelab.feeds = {
    httpPort = lib.mkOption {
      type = lib.types.int;
    };
    host = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    sops.secrets."freshrss/admin" = {
      owner = user;
    };

    services = {
      freshrss = {
        inherit user;

        enable = true;

        authType = "form";
        passwordFile = config.sops.secrets."freshrss/admin".path;

        baseUrl = "https://${cfg.host}";
        virtualHost = cfg.host;
      };

      nginx.virtualHosts.${cfg.host}.listen = [
        {
          port = cfg.httpPort;
          addr = "127.0.0.1";
        }
      ];

      traefik.dynamicConfigOptions.http = {
        routers.feeds = {
          rule = "Host(`${cfg.host}`)";
          service = "feeds";
          tls = {};
        };

        services.feeds = {
          loadBalancer = {
            servers = [{url = "http://localhost:${toString cfg.httpPort}";}];
          };
        };
      };
    };
  };
}
