{
  lib,
  config,
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
    homelab.reverseProxy.vhosts.ntfy = {};

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://${vhost.fqdn}";
        listen-http = ":${toString cfg.port}";
        behind-proxy = true;
      };
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
}
