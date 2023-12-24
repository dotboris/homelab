{...}: let
  httpPort = 8003;
  httpHost = "grafana.dotboris.io";
in {
  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "127.0.0.1";
      http_port = httpPort;
      domain = httpHost;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.grafana = {
      rule = "Host(`${httpHost}`)";
      service = "grafana";
    };

    services.grafana = {
      loadBalancer = {
        servers = [{url = "http://localhost:${toString httpPort}";}];
      };
    };
  };
}
