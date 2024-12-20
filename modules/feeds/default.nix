{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.feeds;
  vhost = config.homelab.reverseProxy.vhosts.feeds;
  user = "freshrss";
in {
  imports = [
    ./backups.nix
  ];

  options.homelab.feeds = {
    httpPort = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = {
    sops.secrets."freshrss/admin" = {
      owner = user;
    };

    homelab = {
      reverseProxy.vhosts.feeds = {};
      homepage.links = [
        {
          category = "services";
          title = "Feed Aggregator";
          icon = "freshrss.svg";
          description = "FreshRSS";
          urlVhost = "feeds";
        }
      ];
    };

    services = {
      freshrss = {
        inherit user;

        enable = true;

        authType = "form";
        passwordFile = config.sops.secrets."freshrss/admin".path;

        baseUrl = "https://${vhost.fqdn}";
        virtualHost = vhost.fqdn;
      };

      nginx.virtualHosts.${vhost.fqdn}.listen = [
        {
          port = cfg.httpPort;
          addr = "127.0.0.1";
        }
      ];
      traefik.dynamicConfigOptions.http = {
        routers.feeds = {
          rule = "Host(`${vhost.fqdn}`)";
          service = "feeds";
          tls = config.homelab.reverseProxy.tls.value;
        };

        services.feeds = {
          loadBalancer = {
            servers = [{url = "http://localhost:${toString cfg.httpPort}";}];
          };
        };
      };
    };
  };
}
