{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.feeds;
    vhost = config.homelab.reverseProxy.vhosts.feeds;
    user = "freshrss";
  in {
    options.homelab.feeds = {
      httpPort = lib.mkOption {
        type = lib.types.int;
      };
    };

    config = {
      homelab = {
        auth.groups = ["feeds"];
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
          authType = "http_auth";
          baseUrl = "https://${vhost.fqdn}";
          virtualHost = vhost.fqdn;
        };
        nginx.virtualHosts.${vhost.fqdn}.listen = [
          {
            port = cfg.httpPort;
            addr = "127.0.0.1";
          }
        ];
        authelia.instances.main.settings.access_control.rules = [
          {
            domain = vhost.fqdn;
            policy = "one_factor";
            subject = "group:feeds";
          }
        ];
        traefik.dynamicConfigOptions.http = {
          routers.feeds = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "feeds";
            middlewares = ["authelia@file"];
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
  };
}
