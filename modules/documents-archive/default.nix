{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.documents-archive;
in {
  options.homelab.documents-archive = {
    port = lib.mkOption {
      type = lib.types.int;
    };
    host = lib.mkOption {
      type = lib.types.str;
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

    services.traefik.dynamicConfigOptions.http = {
      routers.documentsArchive = {
        rule = "Host(`${cfg.host}`)";
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
