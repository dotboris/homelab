{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.keep;
    vhost = config.homelab.reverseProxy.vhosts.keep;
  in {
    options.homelab.keep = {
      enable = lib.mkEnableOption "keep";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.keep = {};
        homepage.links = [
          {
            category = "services";
            title = "Keep";
            icon = "karakeep.svg";
            description = "Karakeep";
            urlVhost = "keep";
          }
        ];
      };
      services = {
        karakeep = {
          enable = true;
          extraEnvironment = {
            PORT = builtins.toString cfg.port;
            DISABLE_NEW_RELEASE_CHECK = "true";
            DISABLE_SIGNUPS = "true";
            LOG_LEVEL = "info";
          };
        };
        traefik.dynamicConfigOptions.http = {
          routers.karakeep = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "karakeep";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.karakeep = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
  };
}
