{...}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints.web.address = ":80";
      entryPoints.websecure.address = ":443"; # TODO: full blown TLS

      api.dashboard = true;

      # Logs
      # accessLog = {};
      # log.level = "INFO";
    };

    dynamicConfigOptions = {
      http = {
        routers.traefikDashboard = {
          rule = "Host(`traefik.dotboris.io`) && PathPrefix(`/dashboard`, `/api`)";
          service = "api@internal";
        };

        routers.homePage = {
          rule = "Host(`home.dotboris.io`)";
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
