{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkEnableOption mkIf mkOption;
  cfg = config.homelab.nextcloud.onlyoffice;
  nextcloudCfg = config.homelab.nextcloud;
  vhost = config.homelab.reverseProxy.vhosts.office;
in {
  options.homelab.nextcloud.onlyoffice = {
    enable = mkEnableOption "NextCloud OnlyOffice integration";
    port = mkOption {type = types.port;};
    nginxPort = mkOption {type = types.port;};
  };
  config = mkIf cfg.enable {
    homelab.reverseProxy.vhosts.office = {};
    services = {
      onlyoffice = {
        inherit (cfg) port;
        enable = true;
        hostname = vhost.fqdn;
      };
      nginx.virtualHosts.${vhost.fqdn}.listen = [
        # onlyoffice uses nginx under the hood. We're using traefik. This moves
        # nginx aside to let traefik take over.
        {
          port = cfg.nginxPort;
          addr = "127.0.0.1";
        }
      ];
      traefik.dynamicConfigOptions.http = {
        routers.onlyoffice = {
          rule = "Host(`${vhost.fqdn}`)";
          service = "onlyoffice";
          tls = config.homelab.reverseProxy.tls.value;
        };
        services.onlyoffice = {
          loadBalancer = {
            servers = [{url = "http://localhost:${toString cfg.nginxPort}";}];
          };
        };
      };
    };
  };
}
