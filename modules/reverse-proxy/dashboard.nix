{...}: {
  flake.modules.nixos.default = {config, ...}: let
    cfg = config.homelab.reverseProxy;
    vhost = config.homelab.reverseProxy.vhosts.traefik;
  in {
    homelab = {
      reverseProxy.vhosts.traefik = {};
      homepage.links = [
        {
          category = "system";
          title = "Traefik Dashboard";
          icon = "traefik.svg";
          urlVhost = "traefik";
          urlPath = "/dashboard/";
          widget = {
            type = "traefik";
            url = "https://${vhost.fqdn}";
          };
        }
      ];
    };

    services.traefik = {
      staticConfigOptions.api.dashboard = true;
      dynamicConfigOptions = {
        http = {
          routers.traefikDashboard = {
            rule = ''
              Host(`${vhost.fqdn}`) &&
              (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
            '';
            service = "api@internal";
            tls = cfg.tls.value;
          };
        };
      };
    };
  };
}
