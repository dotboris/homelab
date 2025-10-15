{...}: {
  flake.modules.nixos.default = {
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
        package = pkgs.netdataCloud;

        config = {
          global = {
            profile = "standalone";
            "default port" = cfg.port;
          };
          db.mode = "dbengine"; # Enables persistent storage
          ml.enabled = "yes";
          registry.enabled = "no"; # No need to phone home
        };

        configDir = {
          "health_alarm_notify.conf" = pkgs.writeText "health_alarm_notify.conf" ''
            SEND_NTFY=YES
            DEFAULT_RECIPIENT_NTFY=https://${vhosts.ntfy.fqdn}/netdata
          '';
        };

        enableAnalyticsReporting = false;
      };
      homelab = {
        reverseProxy.vhosts.netdata = {};
        homepage.links = [
          {
            category = "system";
            title = "Monitoring";
            icon = "netdata.svg";
            description = "NetData";
            urlVhost = "netdata";
            urlPath = "/v3"; # bypasses the login prompt
            widget = {
              type = "netdata";
              url = "https://${vhosts.netdata.fqdn}";
            };
          }
        ];
      };

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
  };
}
