{
  lib,
  config,
  ...
}: let
  inherit (lib) types mkEnableOption mkIf mkOption;
  cfg = config.homelab.nextcloud.onlyoffice;
  vhost = config.homelab.reverseProxy.vhosts.office;
in {
  options.homelab.nextcloud.onlyoffice = {
    enable = mkEnableOption "NextCloud OnlyOffice integration";
    port = mkOption {type = types.port;};
    # TODO: the traefik -> nginx -> onlyoffice setup breaks. Nextcloud fails to
    #   embed to render the document through an iframe because it gets rewritten
    #   to https://{fqdn}:{nginxPort}/ for some reason. Also, HTTPS keeps
    #   getting dropped in those redirects.
    nginxPort = mkOption {type = types.port;};
  };
  config = mkIf cfg.enable {
    # TODO: find a way to pass secret to nextcloud directly instead of having to
    #   set it by hand. Could be doable with occ command.
    sops.secrets."nextcloud/onlyoffice/jwt-secret" = {
      owner = "onlyoffice";
    };
    homelab.reverseProxy.vhosts.office = {};
    services = {
      onlyoffice = {
        inherit (cfg) port;
        enable = true;
        hostname = vhost.fqdn;
        jwtSecretFile = config.sops.secrets."nextcloud/onlyoffice/jwt-secret".path;
      };
      nextcloud = {
        settings.onlyoffice.DocumentServerUrl = "https://${vhost.fqdn}";
        extraApps = {
          inherit
            (config.services.nextcloud.package.packages.apps)
            onlyoffice
            ;
        };
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
