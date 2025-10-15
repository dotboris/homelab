{...}: {
  flake.modules.nixos.default = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.homelab.reverseProxy.tls.snakeOil;
  in {
    options.homelab.reverseProxy.tls.snakeOil = {
      enable = lib.mkEnableOption "reverse proxy snake-oil";
    };

    config = let
      relStateDir = "traefik-tls-snakeoil";
      absStateDir = "/var/lib/${relStateDir}";
    in
      lib.mkIf cfg.enable {
        homelab.reverseProxy.tls.value = {};

        systemd.services."create-traefik-snakoil-cert" = {
          description = "Create a snakeoil certificate for traefik";

          script = ''
            ${pkgs.libressl}/bin/openssl req \
              -x509 \
              -newkey rsa:4096 \
              -keyout "$STATE_DIRECTORY/key.pem" \
              -out "$STATE_DIRECTORY/cert.pem" \
              -days 365 \
              -nodes \
              -subj '/C=CA/CN=*.dotboris.io'
            chmod 644 "$STATE_DIRECTORY/cert.pem"
            chmod 600 "$STATE_DIRECTORY/key.pem"
          '';

          wantedBy = ["traefik.service"];

          unitConfig = {
            Before = ["traefik.service"];
            ConditionPathExists = "!${absStateDir}/cert.pem";
          };

          serviceConfig = {
            User = "traefik";
            Type = "oneshot";
            RemainAfterExit = true;
            StateDirectory = relStateDir;
          };
        };

        services.traefik.dynamicConfigOptions.tls = {
          stores.default.defaultCertificate = {
            certFile = "${absStateDir}/cert.pem";
            keyFile = "${absStateDir}/key.pem";
          };
        };
      };
  };
}
