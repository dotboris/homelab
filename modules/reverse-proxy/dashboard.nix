{config, ...}: let
  cfg = config.homelab.reverseProxy;
  vhost = config.homelab.reverseProxy.vhosts.traefik;
in {
  homelab.reverseProxy.vhosts.traefik = {};
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
}
