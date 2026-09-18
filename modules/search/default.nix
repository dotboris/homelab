{inputs, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    pkgsUnstable = import inputs.nixpkgs-unstable {
      inherit (config.nixpkgs) system;
    };
    cfg = config.homelab.search;
    vhost = config.homelab.reverseProxy.vhosts.search;
  in {
    # Use latest module for comatiblity with latest package
    disabledModules = ["services/networking/searx.nix"];
    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/searx.nix"
    ];

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
          SECRET_KEY=${config.sops.placeholder."search/secret-key"}
        '';
      };
      services = {
        searx = {
          enable = true;
          # Use latest to keep up with engine fixes and workarounds
          package = pkgsUnstable.searxng;
          environmentFile = config.sops.templates."searx.env".path;
          settings = {
            server = {
              port = cfg.port;
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
            engines = [
              # Startpage & variants use anubis PoW. So it was inactive by
              # default. We enable it because it's worth it.
              {
                name = "startpage";
                inactive = false;
              }
              {
                name = "startpage news";
                inactive = false;
              }
              {
                name = "startpage images";
                inactive = false;
              }
            ];
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
