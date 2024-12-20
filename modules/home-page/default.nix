{
  lib,
  config,
  ...
}: let
  inherit (lib) types mkOption;
  cfg = config.homelab.homepage;
  vhost = config.homelab.reverseProxy.vhosts.home;
in {
  imports = [
    ./config.nix
  ];

  options.homelab.homepage = {
    port = mkOption {
      type = types.int;
    };
  };

  config = {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
    };

    homelab.reverseProxy.vhosts.home = {};
    services.traefik.dynamicConfigOptions.http = {
      routers.homePage = {
        rule = "Host(`${vhost.fqdn}`)";
        service = "homePage";
        tls = config.homelab.reverseProxy.tls.value;
      };

      services.homePage = {
        loadBalancer = {
          servers = [{url = "http://localhost:${toString cfg.port}";}];
        };
      };
    };
  };
}
