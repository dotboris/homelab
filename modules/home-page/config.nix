{...}: {
  flake.modules.nixos.default = {
    lib,
    pkgs,
    config,
    ...
  }: let
    inherit (lib) mkOption types;
    inherit (config.homelab.reverseProxy) vhosts;
    cfg = config.homelab.homepage;
    mkLink = link: {
      ${link.title} = {
        inherit (link) icon description widget;
        href = "https://${vhosts.${link.urlVhost}.fqdn}${link.urlPath}";
      };
    };
    mkSection = {
      title,
      category,
      links,
    }: {
      ${title} = lib.pipe links [
        (lib.filter (l: l.category == category))
        (lib.sort (a: b: a.title < b.title))
        (lib.map mkLink)
      ];
    };
  in {
    options.homelab.homepage = {
      links = mkOption {
        description = "Application links to show on the home page";
        default = [];
        type = types.listOf (types.submodule {
          options = {
            category = mkOption {type = types.enum ["services" "system"];};

            # passthrough options
            title = mkOption {type = types.str;};
            description = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            icon = mkOption {type = types.str;};
            widget = mkOption {
              type = types.nullOr types.attrs;
              default = null;
            };

            # href generation
            urlVhost = mkOption {type = types.str;};
            urlPath = mkOption {
              type = types.str;
              default = "/";
            };
          };
        });
      };
    };

    config = {
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
          (mkSection {
            inherit (cfg) links;
            title = "Services";
            category = "services";
          })
          (mkSection {
            inherit (cfg) links;
            title = "System";
            category = "system";
          })
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
                    href = "https://gethomepage.dev";
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
    };
  };
}
