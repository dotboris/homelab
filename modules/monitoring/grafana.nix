{...}: let
  httpPort = 8003;
  httpHost = "grafana.dotboris.io";
in {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = httpPort;
        domain = httpHost;
      };

      users = {
        allow_sign_up = false;
        allow_org_create = false;
      };
      "auth.anonymous" = {
        enabled = true;
        hide_version = true;
      };

      analytics = {
        # We manage the software in nix, this is just noise
        check_for_updates = false;
        check_for_plugin_updates = false;

        # Stop it from phoning home
        feedback_links_enabled = false;
        reporting_enabled = false;
      };
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
