{...}: let
  httpPort = 8004;
  httpHost = "netdata.dotboris.io";
in {
  services.netdata = {
    enable = true;

    config = {
      global = {
        "default port" = httpPort;
      };
    };

    enableAnalyticsReporting = false;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.netdata = {
      rule = "Host(`${httpHost}`)";
      service = "netdata";
    };

    services.netdata = {
      loadBalancer = {
        servers = [{url = "http://localhost:${toString httpPort}";}];
      };
    };
  };
}
