{...}: {
  system.stateVersion = "23.11";

  imports = [
    ../../modules/adblock
    ../../modules/home-page
    ../../modules/monitoring
    ../../modules/remote-access
    ../../modules/reverse-proxy
  ];

  homelab = {
    homepage = {
      port = 8001;
      host = "home.dotboris.io";
    };

    reverseProxy.traefikDashboardHost = "traefik.dotboris.io";

    monitoring = {
      netdata = {
        port = 8002;
        host = "netdata.dotboris.io";
      };
      traefik.exporterPort = 8003;
    };
  };

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
