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
      nginx.virtualHosts.${vhost.fqdn} = {
        extraConfig = ''
          # Force nginx to return relative redirects. This lets the browser
          # figure out the full URL. This ends up working better because it's in
          # front of traefik and has the right protocol, hostname & port.
          absolute_redirect off;
        '';
        listen = [
          # onlyoffice uses nginx under the hood. We're using traefik. This moves
          # nginx aside to let traefik take over.
          {
            port = cfg.nginxPort;
            addr = "127.0.0.1";
          }
        ];
      };

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
