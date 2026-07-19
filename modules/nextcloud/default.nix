{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) types mkEnableOption mkIf mkOption;
    cfg = config.homelab.nextcloud;
    oidcClient = config.homelab.auth.oidcClients.nextcloud;
    vhost = config.homelab.reverseProxy.vhosts.cloud;
    nextcloud = pkgs.nextcloud33;
  in {
    options.homelab.nextcloud = {
      enable = mkEnableOption "NextCloud";
      port = mkOption {type = types.port;};
    };
    config = mkIf cfg.enable {
      homelab = {
        auth = {
          groups = ["nextcloud"];
          oidcClients.nextcloud = {
            group = "nextcloud";
            beforeUnits = [
              "nextcloud-setup.service"
              "phpfpm-nextcloud.service"
            ];
            authorizationPolicy = {
              default_policy = "deny";
              rules = [
                {
                  subject = "group:nextcloud";
                  policy = "one_factor";
                }
              ];
            };
            settings = {
              public = false;
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [
                "https://${vhost.fqdn}/apps/oidc_login/oidc"
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
          maxUploadSize = "8G";
          config = {
            adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
            dbtype = "sqlite";
          };
          secrets = {
            oidc_login_client_id = oidcClient.clientIdPath;
            oidc_login_client_secret = oidcClient.clientSecretPath;
          };
          settings = {
            trusted_proxies = ["127.0.0.1"];
            "overwrite.cli.url" = "https://${vhost.fqdn}";
            maintenance_window_start = 5; # Midnight EST to UTC (hour)

            # SSO
            allow_user_to_change_display_name = false;
            lost_password_link = "disabled";
            oidc_login_provider_url = let
              host = config.homelab.reverseProxy.vhosts.auth;
            in "https://${host.fqdn}";
            oidc_login_auto_redirect = false;
            oidc_login_end_session_redirect = false;
            oidc_login_button_text = "Log in with Authelia";
            oidc_login_hide_password_form = false;
            oidc_login_use_id_token = false;
            oidc_login_attributes = {
              id = "preferred_username";
              name = "name";
              mail = "email";
            };
            oidc_login_default_group = "oidc";
            oidc_login_use_external_storage = false;
            oidc_login_scope = "openid profile email";
            oidc_login_proxy_ldap = false;
            oidc_login_disable_registration = false;
            oidc_login_redir_fallback = false;
            oidc_login_tls_verify = true;
            oidc_create_groups = false;
            oidc_login_webdav_enabled = false;
            oidc_login_password_authentication = false;
            oidc_login_public_key_caching_time = 86400;
            oidc_login_min_time_between_jwks_requests = 10;
            oidc_login_well_known_caching_time = 86400;
            oidc_login_update_avatar = false;
            oidc_login_code_challenge_method = "S256";

            # mail
            mail_smtpmode = "smtp";
            mail_smtphost = "127.0.0.1";
            mail_smtpport = 25;
            mail_smtptimeout = 10;
            mail_smtpsecure = "";
            mail_smtpauth = false;
            mail_domain = config.homelab.reverseProxy.baseDomain;
          };
          phpOptions = {
            # In /settings/admin/overview, there's a warning complaining about
            # this being too low. Increase it until it's happy.
            "opcache.interned_strings_buffer" = 16;
          };
          extraApps = {
            inherit
              (nextcloud.packages.apps)
              bookmarks
              calendar
              contacts
              deck
              notes
              oidc_login
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
  };
}
