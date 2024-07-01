{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.monitoring.netdata;
  vhost = config.homelab.reverseProxy.vhosts.netdata;
in {
  options.homelab.monitoring.netdata = {
    port = lib.mkOption {
      type = lib.types.int;
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

    homelab.reverseProxy.vhosts.netdata = {};
    services.traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        rule = "Host(`${vhost.fqdn}`)";
        service = "netdata";
        tls = config.homelab.reverseProxy.tls.value;
      };

      services.netdata = {
        loadBalancer = {
          servers = [{url = "http://localhost:${toString cfg.port}";}];
        };
      };
    };
  };
}
