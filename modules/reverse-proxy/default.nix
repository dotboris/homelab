{lib, ...}: {
  imports = [
    ./vhosts.nix
    ./fastcgi-stopgap.nix
    ./acme.nix
    ./tls-snakeoil.nix
    ./dashboard.nix
  ];

  options.homelab.reverseProxy = {
    tls.value = lib.mkOption {
      type = lib.types.attrs;
    };
  };

  config = {
    services.traefik = {
      enable = true;

      staticConfigOptions = {
        entryPoints.web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
            permanent = true;
          };
        };
        entryPoints.websecure.address = ":443";

        # Logs
        # accessLog = {};
        log.level = "INFO";
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
