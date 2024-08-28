{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (config.homelab.reverseProxy) vhosts;
  cfg = config.homelab.monitoring.netdata;
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

      configDir = {
        "health_alarm_notify.conf" = pkgs.writeText "health_alarm_notify.conf" ''
          SEND_NTFY=YES
          DEFAULT_RECIPIENT_NTFY=https://${vhosts.ntfy.fqdn}/netdata
        '';
      };

      enableAnalyticsReporting = false;
    };

    homelab.reverseProxy.vhosts.netdata = {};
    services.traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        rule = "Host(`${vhosts.netdata.fqdn}`)";
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
