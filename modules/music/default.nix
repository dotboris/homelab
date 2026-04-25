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
        files.groups.music = [];
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
            Port = cfg.port;
            EnableInsightsCollector = false;
            MusicFolder = cfg.musicDir;
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
        copyparty = {
          volumes."/music" = {
            path = cfg.musicDir;
            access.rwmd = "@music";
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
