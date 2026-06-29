{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    inherit (config.sops) secrets;
    cfg = config.homelab.auth;
    vhost = config.homelab.reverseProxy.vhosts.ldap;
  in {
    options.homelab.auth = {
      ldapAdminPort = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        reverseProxy.vhosts.ldap = {};
        homepage.links = [
          {
            category = "system";
            title = "LDAP";
            icon = "lldap.svg";
            description = "lldap";
            urlVhost = "ldap";
          }
        ];
      };
      users = {
        # services.lldap uses a DynamicUser meaning that we can't normally
        # grant it access to files like the secret below. We create the user
        # & group to allow for this to happen.
        users.lldap = {
          isSystemUser = true;
          group = "lldap";
          extraGroups = ["auth-secrets"];
        };
        groups.lldap = {};
      };
      sops.secrets = {
        "lldap/admin-password" = {
          owner = "lldap"; # hard coded in module
          group = "auth-secrets";
          mode = "440";
        };
      };
      services = {
        lldap = {
          enable = true;
          settings = {
            http_host = "127.0.0.1";
            http_port = cfg.ldapAdminPort;
            http_url = "https://${vhost.fqdn}";
            ldap_host = "127.0.0.1";
            ldap_base_dn = "DC=dotboris,DC=io";
            ldap_user_pass_file = secrets."lldap/admin-password".path;
            force_ldap_user_pass_reset = "always";
          };
        };
        traefik.dynamicConfigOptions.http = {
          routers.ldap = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "ldap";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.ldap = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.ldapAdminPort}";}];
            };
          };
        };
      };
    };
  };
}
