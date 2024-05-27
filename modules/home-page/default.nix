{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.homepage;
in {
  imports = [
    ./config.nix
  ];

  options.homelab.homepage = {
    port = lib.mkOption {
      type = lib.types.int;
    };
    host = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
    };

    services.traefik.dynamicConfigOptions.http = {
      routers.homePage = {
        rule = "Host(`${cfg.host}`)";
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
