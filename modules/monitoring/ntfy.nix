{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.homelab.monitoring.ntfy;
      vhost = config.homelab.reverseProxy.vhosts.ntfy;
    in {
      options.homelab.monitoring.ntfy = {
        port = mkOption {
          type = types.port;
        };
      };

      config = {
        homelab = {
          reverseProxy.vhosts.ntfy = {};
          homepage.links = [
            {
              category = "system";
              title = "Alerts";
              icon = "ntfy.svg";
              description = "ntfy.sh";
              urlVhost = "ntfy";
            }
          ];
        };

        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = "https://${vhost.fqdn}";
            listen-http = ":${toString cfg.port}";
            behind-proxy = true;
          };
        };

        systemd.services."ntfy-send@" = {
          description = "send message to ntfy";
          serviceConfig = {
            Type = "oneshot";
          };
          environment = {
            PAYLOAD = "%I";
          };
          path = [pkgs.curl];
          script = ''
            curl \
              --fail --silent --show-error \
              -X POST https://${vhost.fqdn} \
              -d "$PAYLOAD"
          '';
        };

        services.traefik.dynamicConfigOptions.http = {
          routers.ntfy = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "ntfy";
            tls = config.homelab.reverseProxy.tls.value;
          };

          services.ntfy = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
}
