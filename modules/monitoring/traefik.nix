{pkgs, ...}: let
  metricsPort = 8005;
  entryPoint = "metrics";
  yaml = pkgs.formats.yaml {};
in {
  # Enable Traefik prom exporter
  services.traefik.staticConfigOptions = {
    metrics.prometheus.entryPoint = entryPoint;
    entryPoints.${entryPoint}.address = ":${toString metricsPort}";
  };

  # Configure Netdata to listen to it
  services.netdata.configDir."go.d/traefik.conf" = yaml.generate "traefik.conf" {
    jobs = [
      {
        name = "local";
        url = "http://localhost:${toString metricsPort}/metrics";
      }
    ];
  };
}
