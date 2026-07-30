{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.auth;
    vhost = config.homelab.reverseProxy.vhosts.auth;
    redisCfg = config.services.redis.servers.authelia-sessions;
    sessionSecret = config.services.gen-secrets.secrets.authelia-session;
  in {
    config = lib.mkIf cfg.enable {
      services.gen-secrets.secrets.authelia-session = {
        requiredBy = ["authelia.service"];
        before = ["authelia.service"];
      };
      services.redis.servers.authelia-sessions = {
        enable = true;
        appendOnly = true;
      };
      systemd.services.authelia = {
        environment = {
          AUTHELIA_SESSION_SECRET_FILE = "%d/session";
        };
        serviceConfig = {
          SupplementaryGroups = [redisCfg.group];
          LoadCredential = [
            "session:${sessionSecret.path}"
          ];
        };
      };
      services.authelia.instances.main = {
        settings = {
          session = {
            cookies = [
              {
                domain = config.homelab.reverseProxy.baseDomain;
                authelia_url = "https://${vhost.fqdn}";
              }
            ];
            redis.host = redisCfg.unixSocket;
          };
        };
      };
    };
  };
}
