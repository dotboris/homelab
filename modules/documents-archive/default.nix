{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.documents-archive;
  vhost = config.homelab.reverseProxy.vhosts.archive;
in {
  imports = [
    ./backups.nix
  ];

  options.homelab.documents-archive = {
    port = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = {
    sops.secrets."paperless/admin" = {
      owner = config.services.paperless.user;
    };

    services.paperless = {
      inherit (cfg) port;
      enable = true;
      passwordFile = config.sops.secrets."paperless/admin".path;
    };

    homelab.reverseProxy.vhosts.archive = {};
    services.traefik.dynamicConfigOptions.http = {
      routers.documentsArchive = {
        rule = "Host(`${vhost.fqdn}`)";
        service = "documentsArchive";
        tls = config.homelab.reverseProxy.tls.value;
      };

      services.documentsArchive = {
        loadBalancer = {
          servers = [{url = "http://localhost:${toString cfg.port}";}];
        };
      };
    };
  };
}
