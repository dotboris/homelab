{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.homelab;
in {
  # The `homepage-dashboard` module doesn't handle the config at all. Instead it
  # just sets this environment variable to `/var/lib/homepage-dashboard`. I want
  # to manage the config in the nix store so we override that variable.
  systemd.services.homepage-dashboard.environment.HOMEPAGE_CONFIG_DIR = let
    format = pkgs.formats.yaml {};
    # Even if they're empty, all the config files need to be here. If they're
    # not, homepage will try to copy its default config in. This will fail
    # because it's not allowed to write in the nix store.
    configDir = pkgs.linkFarm "homepage-dashboard-config" {
      "settings.yaml" = format.generate "settings.yaml" {
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
      "services.yaml" = format.generate "services.yaml" [
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
      "widgets.yaml" = format.generate "widgets.yaml" [
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
      "bookmarks.yaml" = format.generate "bookmarks.yaml" [
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
      "docker.yaml" = format.generate "docker.yaml" {};
      "kubernetes.yaml" = format.generate "kubernetes.yaml" {
        mode = "disabled";
      };
      "custom.css" = pkgs.writeText "custom.css" '''';
      "custom.js" = pkgs.writeText "custom.js" '''';
    };
  in
    lib.mkForce "${configDir}";
}
