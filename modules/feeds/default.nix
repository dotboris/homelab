{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.feeds;
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
    services.freshrss = {
      enable = true;

      authType = "none"; # TODO: feeds auth

      baseUrl = "http://${cfg.host}"; # TODO: ssl
      virtualHost = cfg.host;
    };

    services.nginx.virtualHosts.${cfg.host}.listen = [
      {
        port = cfg.httpPort;
        addr = "127.0.0.1";
      }
    ];

    services.traefik.dynamicConfigOptions.http = {
      routers.feeds = {
        rule = "Host(`${cfg.host}`)";
        service = "feeds";
      };

      services.feeds = {
        loadBalancer = {
          servers = [{url = "http://localhost:${toString cfg.httpPort}";}];
        };
      };
    };
  };
}
