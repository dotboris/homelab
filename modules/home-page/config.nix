{
  pkgs,
  config,
  ...
}: let
  cfg = config.homelab;
in {
  services.homepage-dashboard = {
    settings = {
      title = "Home Lab";
      background = "https://images.unsplash.com/photo-1702933018162-b338fceacc26?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
      cardBlur = "sm";
      theme = "dark";
      color = "slate";
      iconStyle = "theme";

      language = "en-CA";

      target = "_blank"; # open links in new tabs

      hideVersion = true;
      disableCollapse = true;

      # Hack: homepage outputs to both the console and to the filesystem. Both
      # of these log transports are hard-coded in. See:
      # https://github.com/gethomepage/homepage/blob/4d6754e4a7258c46047d3cc2ca2e3fe63f6df76a/src/utils/logger.js#L41-L68
      #
      # That means that you have to log to file. The output path for the logs
      # ends up being `{logpath}/logs/homepage.log`. We're running a systemd
      # service so the console logs are already in the journal. These file
      # logs are useless for us. We fiddle the path to ensure that they point
      # to `/dev/null`.
      logpath = pkgs.linkFarm "homepage-dashboard-null-logs" {
        "logs/homepage.log" = "/dev/null";
      };
    };

    services = [
      {
        Services = [
          {
            "Feed Aggregator" = {
              icon = "freshrss.svg";
              href = "https://${cfg.feeds.host}";
            };
          }
        ];
      }
      {
        System = [
          {
            "Monitoring (NetData)" = {
              icon = "netdata.svg";
              href = "https://${cfg.monitoring.netdata.host}";
            };
          }
          {
            "Traefik Dashboard" = {
              icon = "traefik.svg";
              href = "https://${cfg.reverseProxy.traefikDashboardHost}/dashboard/";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          text_size = "xl";
          locale = "en-CA";
          format = {
            dateStyle = "full";
            timeStyle = "short";
          };
        };
      }
    ];

    bookmarks = [
      {
        Code = [
          {
            "HomeLab Repo" = [
              {
                icon = "si-github";
                href = "https://github.com/dotboris/homelab";
              }
            ];
          }
        ];
      }
      {
        Documetation = [
          {
            Homepage = [
              {
                icon = "mdi-home";
                href = "https://gethomepage.dev/main/";
              }
            ];
          }
          {
            "Bocky (Adblocking DNS)" = [
              {
                icon = "mdi-advertisements-off";
                href = "https://0xerr0r.github.io/blocky/main/";
              }
            ];
          }
          {
            "Traefik" = [
              {
                icon = "traefik.svg";
                href = "https://doc.traefik.io/traefik/";
              }
            ];
          }
        ];
      }
    ];

    kubernetes.mode = "disabled";
  };
}
