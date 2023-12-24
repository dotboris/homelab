{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.monitoring.netdata;
in {
  options.homelab.monitoring.netdata = {
    port = lib.mkOption {
      type = lib.types.int;
    };
    host = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    services.netdata = {
      enable = true;

      config = {
        global = {
          "default port" = cfg.port;
        };

        # Enables persistent storage
        db.mode = "dbengine";
      };

      enableAnalyticsReporting = false;
    };

    services.traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        rule = "Host(`${cfg.host}`)";
        service = "netdata";
      };

      services.netdata = {
        loadBalancer = {
          servers = [{url = "http://localhost:${toString cfg.port}";}];
        };
      };
    };
  };
}
