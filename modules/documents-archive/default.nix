{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.homelab.documents-archive;
    paperlessCfg = config.services.paperless;
    vhost = config.homelab.reverseProxy.vhosts.archive;
  in {
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
        environmentFile = "${paperlessCfg.dataDir}/generated.env";
        settings = {
          PAPERLESS_URL = "https://${vhost.fqdn}";
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
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
          PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
        };
      };

      systemd.services.paperless-envfile = let
        deps = [
          "paperless-consumer.service"
          "paperless-scheduler.service"
          "paperless-task-queue.service"
          "paperless-web.service"
        ];
      in {
        description = "Generate paperless envfile";
        wantedBy = deps;
        unitConfig.Before = deps;
        serviceConfig = {
          Type = "oneshot";
          User = paperlessCfg.user;
        };
        path = [pkgs.jq];
        environment = {
          inherit (paperlessCfg) dataDir;
          inherit
            (config.homelab.auth.oidcClients.paperless)
            clientIdPath
            clientSecretPath
            ;
          authUrl = let
            host = config.homelab.reverseProxy.vhosts.auth;
          in "https://${host.fqdn}";
        };
        script = ''
          umask 177
          clientId="$(cat "$clientIdPath")"
          clientSecret="$(cat "$clientSecretPath")"
          res="$(
            jq \
              --null-input \
              --compact-output \
              --arg authUrl "$authUrl" \
              --arg clientId "$clientId" \
              --arg clientSecret "$clientSecret" \
              '{
                "openid_connect": {
                  "SCOPE": ["openid", "profile", "email"],
                  "OAUTH_PKCE_ENABLED": true,
                  "APPS": [
                    {
                      "provider_id": "authelia",
                      "name": "Authelia",
                      "client_id": $clientId,
                      "secret": $clientSecret,
                      "settings": {
                        "server_url": $authUrl,
                        "token_auth_method": "client_secret_basic"
                      }
                    }
                  ]
                }
              }'
          )"
          echo "PAPERLESS_SOCIALACCOUNT_PROVIDERS=$res" > "$dataDir/generated.env";
        '';
      };

      homelab = {
        auth = {
          groups = ["documents-archive"];
          oidcClients.paperless = {
            group = "paperless";
            beforeUnits = ["paperless-envfile.service"];
            authorizationPolicy = {
              default_policy = "deny";
              rules = [
                {
                  subject = "group:documents-archive";
                  policy = "two_factor";
                }
              ];
            };
            settings = {
              public = false;
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [
                "https://${vhost.fqdn}/accounts/oidc/authelia/login/callback/"
              ];
              scopes = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              response_types = ["code"];
              grant_types = ["authorization_code"];
              access_token_signed_response_alg = "none";
              userinfo_signed_response_alg = "none";
              token_endpoint_auth_method = "client_secret_basic";
            };
          };
        };
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
  };
}
