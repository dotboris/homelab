{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.sops) secrets;
    cfg = config.homelab.auth;
    vhost = config.homelab.reverseProxy.vhosts.auth;
    autheliaCfg = config.services.authelia.instances.main;
    lldapCfg = config.services.lldap;
    secretsDir = "/var/lib/authelia/secrets";
  in {
    options.homelab.auth = {
      enable = lib.mkEnableOption "Central Authentication / SSO";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.auth = {};
        homepage.links = [
          {
            category = "system";
            title = "SSO";
            icon = "authelia.svg";
            description = "Authelia";
            urlVhost = "auth";
          }
        ];
      };
      users = {
        # We need a group to share secrets between auth components
        users.${autheliaCfg.user}.extraGroups = ["auth-secrets"];
        groups.auth-secrets = {};
      };
      services = {
        authelia.instances.main = {
          enable = true;
          name = ""; # Makes this the "authelia" instance with no suffix
          environmentVariables = {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = secrets."lldap/admin-password".path;
          };
          secrets = {
            jwtSecretFile = "${secretsDir}/jwt-secret";
            storageEncryptionKeyFile = "${secretsDir}/storage-encryption-key";
            sessionSecretFile = "${secretsDir}/session-secret";
          };
          settings = {
            theme = "dark";
            log.format = "text";
            access_control.default_policy = "one_factor"; # TODO: not sure
            authentication_backend.ldap = {
              address = let
                host = lldapCfg.settings.ldap_host;
                port = lldapCfg.settings.ldap_port;
              in "ldap://${host}:${toString port}";
              implementation = "lldap";
              user = "UID=admin,OU=people,DC=dotboris,DC=io";
              base_dn = "DC=dotboris,DC=io";
            };
            notifier.filesystem.filename = "/var/lib/authelia/notification.txt";
            server = {
              address = "tcp://127.0.0.1:${toString cfg.port}";
              endpoints.authz.forward-auth.implementation = "ForwardAuth";
            };
            session.cookies = [
              {
                domain = config.homelab.reverseProxy.baseDomain;
                authelia_url = "https://${vhost.fqdn}";
              }
            ];
            storage.local.path = "/var/lib/authelia/db.sqlite3";
          };
        };
        traefik.dynamicConfigOptions.http = {
          middlewares.authelia.forwardAuth = {
            address = "http://localhost:${toString cfg.port}/api/authz/forward-auth";
            trustForwardHeader = true;
            maxResponseBodySize = 8192;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ];
          };
          routers.auth = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "auth";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.auth = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
      systemd = {
        tmpfiles.rules = [
          "d ${secretsDir} 0700 ${autheliaCfg.user} ${autheliaCfg.group}"
        ];
        services.authelia.preStart = lib.mkBefore (lib.getExe (
          pkgs.writeShellApplication {
            name = "authelia-generate-secrets";
            runtimeEnv = {
              inherit secretsDir;
            };
            runtimeInputs = [
              pkgs.openssl
            ];
            text = ''
              echo '[start] authelia-generate-secrets'
              umask 177 # rw for user
              secrets=(
                jwt-secret
                storage-encryption-key
                session-secret
              )
              for s in "''${secrets[@]}"; do
                if [ ! -f "$secretsDir/$s" ]; then
                  openssl rand -hex 64 > "$secretsDir/$s"
                  echo "Generated $secretsDir/$s"
                fi
              done
              echo '[stop] authelia-generate-secrets'
            '';
          }
        ));
      };
    };
  };
}
