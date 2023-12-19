{...}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints.web.address = ":80";

      # TODO: full blown TLS
      entryPoints.websecure.address = ":443";

      api.dashboard = true;
    };

    dynamicConfigOptions = {
      http = {
        routers.traefikDashboard = {
          rule = "Host(`localhost`) && PathPrefix(`/dashboard`, `/api`)";
          service = "api@internal";
        };

        routers.homePage = {
          rule = "Host(`localhost`)";
          service = "homePage";
        };

        services.homePage = {
          loadBalancer = {
            servers = [{url = "http://localhost:8001";}];
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
