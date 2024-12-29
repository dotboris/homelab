{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkEnableOption mkIf mkOption;
  cfg = config.homelab.nextcloud;
  vhost = config.homelab.reverseProxy.vhosts.cloud;
  nextcloud = pkgs.nextcloud30;
in {
  imports = [
    ./backups.nix
    ./onlyoffice.nix
  ];

  options.homelab.nextcloud = {
    enable = mkEnableOption "NextCloud";
    port = mkOption {type = types.port;};
  };
  config = mkIf cfg.enable {
    homelab = {
      reverseProxy.vhosts.cloud = {};
      homepage.links = [
        {
          category = "services";
          title = "NextCloud";
          icon = "nextcloud.svg";
          description = "Self-hosted cloud storage and apps";
          urlVhost = "cloud";
        }
      ];
    };

    sops.secrets."nextcloud/admin-password" = {
      owner = "nextcloud";
    };

    services = {
      nextcloud = {
        enable = true;
        package = nextcloud;
        hostName = vhost.fqdn;
        https = true;
        webfinger = true;
        appstoreEnable = false;
        config = {
          adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
        };
        settings = {
          trusted_proxies = ["127.0.0.1"];
          "overwrite.cli.url" = "https://${vhost.fqdn}";
          maintenance_window_start = 5; # Midnight EST to UTC (hour)
        };
        phpOptions = {
          # In /settings/admin/overview, there's a warning complaining about
          # this being too low. Increase it until it's happy.
          "opcache.interned_strings_buffer" = 16;
        };
        extraApps = {
          inherit
            (nextcloud.packages.apps)
            calendar
            contacts
            deck
            notes
            tasks
            ;
        };
      };
      nginx.virtualHosts.${vhost.fqdn}.listen = [
        {
          inherit (cfg) port;
          addr = "127.0.0.1";
        }
      ];
      traefik.dynamicConfigOptions.http = {
        routers.nextcloud = {
          rule = "Host(`${vhost.fqdn}`)";
          service = "nextcloud";
          tls = config.homelab.reverseProxy.tls.value;
        };
        services.nextcloud = {
          loadBalancer = {
            servers = [{url = "http://localhost:${toString cfg.port}";}];
          };
        };
      };
    };
  };
}
