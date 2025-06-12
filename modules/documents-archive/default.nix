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
      settings = {
        PAPERLESS_URL = "https://${vhost.fqdn}";
        PAPERLESS_OCR_USER_ARGS = {
          # Some documents (like AWS bills) get digitally signed. That's pretty
          # neat but in this context it's not helpful. The OCR system refuses to
          # handle such files because it would invalidate the signature. I'd
          # rather invalidate the signature than not being able to ingest the
          # document to paperless. This setting allows the OCR engine to
          # invalidate the signature.
          #
          # See: https://github.com/paperless-ngx/paperless-ngx/discussions/4047
          invalidate_digital_signatures = true;
        };
        # Short expiration to force re-login. Some of these documents are
        # sensitive. Better not get screwed by a stolen cookie
        PAPERLESS_SESSION_COOKIE_AGE = 2 * 60 * 60; # seconds
      };
    };

    homelab = {
      reverseProxy.vhosts.archive = {};
      homepage.links = [
        {
          category = "services";
          title = "Documents Archive";
          icon = "paperless-ngx.svg";
          description = "paperless-ngx";
          urlVhost = "archive";
        }
      ];
    };

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
