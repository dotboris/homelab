{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.music;
    vhost = config.homelab.reverseProxy.vhosts.music;
  in {
    options.homelab.music = {
      enable = lib.mkEnableOption "music streaming";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.music = {};
        homepage.links = [
          {
            category = "services";
            title = "Music";
            icon = "navidrome.svg";
            description = "Navidrome";
            urlVhost = "music";
          }
        ];
      };
      services = {
        navidrome = {
          enable = true;
          settings = {
            Port = cfg.port;
            EnableInsightsCollector = false;
          };
        };
        traefik.dynamicConfigOptions.http = {
          routers.music = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "music";
            tls = config.homelab.reverseProxy.tls.value;
          };

          services.music = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
  };
}
