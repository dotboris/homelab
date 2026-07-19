{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.books;
    vhost = config.homelab.reverseProxy.vhosts.books;
  in {
    options.homelab.books = {
      enable = lib.mkEnableOption "Book management";
      port = lib.mkOption {
        type = lib.types.port;
      };
    };
    config = lib.mkIf cfg.enable {
      homelab = {
        auth.groups = ["books"];
        reverseProxy.vhosts.books = {};
        homepage.links = [
          {
            category = "services";
            title = "Books";
            icon = "sh-grimmory.svg";
            description = "Grimmory";
            urlVhost = "books";
          }
        ];
      };
      services = {
        traefik.dynamicConfigOptions.http = {
          routers.books = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "books";
            tls = config.homelab.reverseProxy.tls.value;
          };
          services.books = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
  };
}
