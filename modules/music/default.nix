{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.music;
    copypartyCfg = config.services.copyparty;
    navidromeCfg = config.services.navidrome;
    vhost = config.homelab.reverseProxy.vhosts.music;
  in {
    options.homelab.music = {
      enable = lib.mkEnableOption "music streaming";
      port = lib.mkOption {
        type = lib.types.port;
      };
      musicDir = lib.mkOption {
        type = lib.types.str;
        default = "/srv/music";
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        auth.groups = ["music" "music-manager"];
        reverseProxy.vhosts.music = {};
        homepage.links = [
          {
            category = "services";
            title = "Music";
            icon = "navidrome.png"; # using PNG because the SVG is animated
            description = "Navidrome";
            urlVhost = "music";
          }
        ];
      };
      users.groups.music = {
        members = [
          copypartyCfg.user
          navidromeCfg.user
          "dotboris"
        ];
      };
      systemd.tmpfiles.rules = [
        "d ${cfg.musicDir} 2770 root music"
      ];
      services = {
        navidrome = {
          enable = true;
          settings = {
            LogLevel = "info";
            Port = cfg.port;
            EnableInsightsCollector = false;
            MusicFolder = cfg.musicDir;
            EnableUserEditing = true; # Used for app access
            ExtAuth = {
              LogoutURL = "https://${config.homelab.reverseProxy.vhosts.auth.fqdn}/logout";
              TrustedSources = "127.0.0.1/32";
              UserHeader = "Remote-User";
            };
          };
        };
        authelia.instances.main.settings.access_control.rules = [
          # For subsonic clients, we can't use SSO (protocol doesn't support it)
          # Users will have to set a password in navidrome and use that.
          {
            domain = vhost.fqdn;
            policy = "bypass";
            resources = [
              "^/share([/?].*)?$"
              "^/rest([/?].*)?$"
            ];
          }
          # Fall back to one factor for the rest
          {
            domain = vhost.fqdn;
            policy = "one_factor";
            subject = "group:music";
          }
        ];
        traefik.dynamicConfigOptions.http = {
          routers.music = {
            rule = "Host(`${vhost.fqdn}`)";
            middlewares = ["authelia@file"];
            service = "music";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.music = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
        copyparty = {
          volumes."/music" = {
            path = cfg.musicDir;
            access.rwmd = "@music-manager";
            flags = {
              chmod_f = "0660";
              chmod_d = "0770";
            };
          };
        };
      };
    };
  };
}
