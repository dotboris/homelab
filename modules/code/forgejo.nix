{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.code;
    vhost = config.homelab.reverseProxy.vhosts.code;
  in {
    options.homelab.code = {
      enable = lib.mkEnableOption "code forge";
      httpPort = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      services.forgejo = {
        enable = true;
        lfs.enable = true;
        settings = {
          # log.LEVEL = "Trace";
          server = {
            PROTOCOL = "http";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = cfg.httpPort;
            DOMAIN = vhost.fqdn;
            ROOT_URL = "https://${vhost.fqdn}/";
          };
          cache = {
            ADAPTER = "twoqueue";
            HOST = builtins.toJSON {
              size = 100;
              recent_ratio = 0.25;
              ghost_ratio = 0.5;
            };
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtp";
            SMTP_ADDR = "127.0.0.1";
            SMTP_PORT = 25;
            FROM = "Forgejo <noreply@${config.homelab.reverseProxy.baseDomain}>";
          };
          session = {
            COOKIE_SECURE = true;
          };
        };
      };
      homelab.reverseProxy.vhosts.code = {};
      services.traefik.dynamicConfigOptions.http = {
        routers.code = {
          rule = "Host(`${vhost.fqdn}`)";
          service = "code";
          tls = config.homelab.reverseProxy.tls.value;
        };
        services.code.loadBalancer.servers = [
          {url = "http://localhost:${toString cfg.httpPort}";}
        ];
      };
    };
  };
}
