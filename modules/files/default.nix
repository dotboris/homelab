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
      groups = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {};
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
        files = {
          users = [
            "dotboris" # always a user for ourselves
          ];
          groups.admin = [];
        };
      };
      sops.secrets = lib.pipe cfg.users [
        (lib.map (user: {
          "copyparty/users/${user}" = {
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
              ${user}.passwordFile = config.sops.secrets."copyparty/users/${user}".path;
            }))
            lib.mkMerge
          ];
          # Add ourselves to every group. Groups require at least one user.
          groups = lib.mapAttrs (_: users: users ++ ["dotboris"]) cfg.groups;
          settings = {
            i = "127.0.0.1";
            p = cfg.port;
            http-only = true; # reverse proxy does the tls termination
            no-crt = true; # don't need a cert
            usernames = true; # require usernames for auth
            no-robots = true; # request no crawling in headers
            dotpart = true; # hide partial upload from listing

            # UI / Display settings
            name = vhost.fqdn; # server name in top left
            name-url = "https://${vhost.fqdn}"; # where the name links to
            site = "https://${vhost.fqdn}"; # base url for sharing

            # Indexing
            e2dsa = true; # index files (upload, scan on boot, incl readonly)
            e2ts = true; # metadata indexing (upload, scan on boot)
            e2vu = true; # validates integrity (on boot, fixes hashes)

            # Reverse proxy settings
            rproxy = 1;
            xff-hdr = "x-forwarded-for";
            xff-src = "lan";
            xf-host = "x-forwarded-host";
            xf-proto = "x-forwarded-proto";
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
