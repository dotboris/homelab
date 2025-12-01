{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.search;
    vhost = config.homelab.reverseProxy.vhosts.search;
  in {
    options.homelab.search = {
      enable = lib.mkEnableOption "homelab search";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.search = {};
        homepage.links = [
          {
            category = "services";
            title = "Search";
            icon = "searxng.svg";
            description = "SearXNG";
            urlVhost = "search";
          }
        ];
      };
      sops = {
        secrets."search/secret-key" = {};
        templates."searx.env".content = ''
          SEARCH_KEY=${config.sops.placeholder."search/secret-key"}
        '';
      };
      services = {
        searx = {
          enable = true;
          environmentFile = config.sops.templates."searx.env".path;
          settings = {
            server = {
              port = cfg.port;
              bind_address = "127.0.0.1";
              secret_key = "$SECRET_KEY";
            };
          };
        };
        traefik.dynamicConfigOptions.http = {
          routers.search = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "search";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.search.loadBalancer.servers = [
            {url = "http://localhost:${toString cfg.port}";}
          ];
        };
      };
    };
  };
}
