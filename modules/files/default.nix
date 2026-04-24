{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.files;
    copypartyCfg = config.services.copyparty;
    vhost = config.homelab.reverseProxy.vhosts.files;
  in {
    options.homelab.files = {
      enable = lib.mkEnableOption "file browser";
      port = lib.mkOption {
        type = lib.types.port;
      };
      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
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
      sops.secrets = lib.pipe cfg.users [
        (lib.map (user: {
          "copyparty/users/${user}/password" = {
            owner = copypartyCfg.user;
          };
        }))
        lib.mkMerge
      ];
      services = {
        copyparty = {
          enable = true;
          accounts = lib.pipe cfg.users [
            (lib.map (user: {
              ${user}.passwordFile = config.sops.secrets."copyparty/users/${user}/password".path;
            }))
            lib.mkMerge
          ];
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
