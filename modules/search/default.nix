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
              base_url = "https://${vhost.fqdn}";
              secret_key = "$SECRET_KEY";
              method = "GET";
              default_http_headers = {
                X-Content-Type-Options = "nosniff";
                X-Download-Options = "noopen";
                X-Robots-Tag = "noindex, nofollow";
                Referrer-Policy = "no-referrer";
              };
            };
            search = {
              formats = [
                "html"
                "json"
              ];
              autocomplete = "brave";
              autocomplete_min = 4;
              favicon_resolver = "duckduckgo";
            };
          };
          runInUwsgi = true;
          uwsgiConfig = {
            http = "127.0.0.1:${builtins.toString cfg.port}";
            disable-logging = true; # It logs queries by default
            workers = "%k";
            threads = 4;
            offload-threads = "%k";
          };
          redisCreateLocally = true;
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
