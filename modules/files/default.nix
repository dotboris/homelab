{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.files;
    vhost = config.homelab.reverseProxy.vhosts.files;
  in {
    options.homelab.files = {
      enable = lib.mkEnableOption "file browser";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };

    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.files = {};
        homepage.links = [
          {
            category = "system";
            title = "Files";
            icon = "copyparty.svg";
            description = "Copyparty";
            urlVhost = "files";
          }
        ];
      };
      services = {
        copyparty = {
          enable = true;
          accounts = {
            dotboris.passwordFile = "supersecret";
          };
          settings = {
            p = cfg.port;
          };
        };
        traefik.dynamicConfigOptions.http = {
          routers.files = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "files";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.files = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
  };
}
