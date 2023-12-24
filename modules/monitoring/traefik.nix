{
  lib,
  pkgs,
  config,
  ...
}: let
  entryPoint = "metrics";
  yaml = pkgs.formats.yaml {};
  cfg = config.homelab.monitoring.traefik;
in {
  options.homelab.monitoring.traefik = {
    exporterPort = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = {
    # Enable Traefik prom exporter
    services.traefik.staticConfigOptions = {
      metrics.prometheus.entryPoint = entryPoint;
      entryPoints.${entryPoint}.address = ":${toString cfg.exporterPort}";
    };

    # Configure Netdata to listen to it
    services.netdata.configDir."go.d/traefik.conf" = yaml.generate "traefik.conf" {
      jobs = [
        {
          name = "local";
          url = "http://localhost:${toString cfg.exporterPort}/metrics";
        }
      ];
    };
  };
}
