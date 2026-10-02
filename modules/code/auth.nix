{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.code;
    vhost = config.homelab.reverseProxy.vhosts.code;
  in {
    config = lib.mkIf cfg.enable {
      homelab.auth.groups = ["code"];
      services.authelia.instances.main.settings.access_control.rules = [
        {
          domain = vhost.fqdn;
          policy = "one_factor";
          subject = "group:code";
        }
      ];
      services.traefik.dynamicConfigOptions.http.routers.code.middlewares = [
        "authelia@file"
      ];
      services.forgejo.settings = {
        service = {
          ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
          ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
          ENABLE_REVERSE_PROXY_EMAIL = true;
          ENABLE_REVERSE_PROXY_FULL_NAME = true;
          DISABLE_REGISTRATION = true;
        };
        security = {
          REVERSE_PROXY_AUTHENTICATION_USER = "Remote-User";
          REVERSE_PROXY_AUTHENTICATION_EMAIL = "Remote-Email";
          REVERSE_PROXY_AUTHENTICATION_FULL_NAME = "Remote-Name";
          REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.0/8";
        };
      };
    };
  };
}
