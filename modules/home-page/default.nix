{...}: let
  port = 8001;
  hostname = "home.dotboris.io";
in {
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.homePage = {
      rule = "Host(`${hostname}`)";
      service = "homePage";
    };

    services.homePage = {
      loadBalancer = {
        servers = [{url = "http://localhost:${toString port}";}];
      };
    };
  };
}
