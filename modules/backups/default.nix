{moduleWithSystem, ...}: {
  flake.modules.nixos.default = moduleWithSystem ({self', ...}: {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.homelab.backups;
    sbCfg = config.services.standard-backups;
    ntfyTopic = "https://${config.homelab.reverseProxy.vhosts.ntfy.fqdn}/backups";
    variants = lib.pipe cfg.retentionProfiles [
      (lib.mapAttrs (_: value: {
        forget = lib.recursiveUpdate value._forgetOption {
          options.prune = true;
        };
      }))
    ];
  in {
    options.homelab.backups = {
      enable = lib.mkEnableOption "homelab backups";
      recipes = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = {};
        description = ''
          Recipes for backing up applications. These are in the
          standard-backups format. Each recipe generates a corresponding job in
          standard-backups. This should be used by modules to enable backing up
          the apps they provision / manage.
        '';
      };
      joinGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of groups to join the backup user to. This is useful to give the
          backup user access to files they normally wouldn't have access to.
        '';
      };
      jobs = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            retentionProfile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            schedule = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                When to run the this backup job. Value is a string who's format
                is described by systemd.time(7)
              '';
            };
          };
        });
        default = {};
        description = ''
          Configurations for jobs. Jobs are automatically detected based on
          reciped installed by other modules.
        '';
      };
      defaultRetentionProfile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Which retention profile to use by default. If not specified a
          retention profile will need to be specified for every job.
        '';
      };
      retentionProfiles = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.submodule ({config, ...}: let
          retentionOption = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
        in {
          options = {
            last = retentionOption;
            daily = retentionOption;
            weekly = retentionOption;
            monthly = retentionOption;
            yearly = retentionOption;
            _valid = lib.mkOption {type = lib.types.bool;};
            _name = lib.mkOption {type = lib.types.str;};
            _forgetOption = lib.mkOption {type = lib.types.anything;};
          };
          config = let
            anySet =
              (config.last != null)
              || (config.daily != null)
              || (config.weekly != null)
              || (config.monthly != null)
              || (config.yearly != null);
          in {
            _valid = anySet;
            _name = config._module.args.name;
            _forgetOption = lib.mkIf anySet {
              enable = true;
              options = {
                keep-last = lib.mkIf (config.last != null) config.last;
                keep-daily = lib.mkIf (config.daily != null) config.daily;
                keep-weekly = lib.mkIf (config.weekly != null) config.weekly;
                keep-monthly = lib.mkIf (config.monthly != null) config.monthly;
                keep-yearly = lib.mkIf (config.yearly != null) config.yearly;
              };
            };
          };
        }));
        default = {};
        description = ''
          Profiles describing how long to keep backups around. This option
          enables backups to be deleted automatically. Use with case.
        '';
      };
      _destinations = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        description = ''
          Allows destination modules to register their destination
          configuration. These will land in
          `services.standard-backups.settings.destinations` with some defaults
          applied.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = lib.pipe cfg.retentionProfiles [
        (lib.mapAttrsToList (key: value: {
          assertion = value._valid;
          message = "homelab.backups.retentionProfiles.${key}: at least one retention option must be set";
        }))
      ];

      services.standard-backups = {
        enable = true;
        user = "backups";
        group = "backups";
        extraPackages =
          [self'.packages.standard-backups-restic-backend]
          ++ (builtins.attrValues cfg.recipes);
        jobSchedules = lib.pipe cfg.jobs [
          (lib.mapAttrsToList (k: v:
            lib.mkIf (v.schedule != null) {
              ${k} = v.schedule;
            }))
          lib.mkMerge
        ];

        settings = {
          destinations = lib.pipe cfg._destinations [
            (lib.mapAttrs (_: value:
              lib.recursiveUpdate value {
                inherit variants;
                backend = "restic";
                default-variant =
                  lib.mkIf
                  (cfg.defaultRetentionProfile != null)
                  cfg.defaultRetentionProfile;
                # sets the host and picks it up during operations like forget
                options.env.RESTIC_HOST = config.networking.hostName;
              }))
          ];
          jobs = lib.pipe cfg.recipes [
            (lib.mapAttrs (name: _: let
              job = cfg.jobs.${name} or {retentionProfile = null;};
              suffix =
                lib.optionalString
                (job.retentionProfile != null)
                "/${job.retentionProfile}";
            in {
              recipe = name;
              backup-to = lib.pipe cfg._destinations [
                builtins.attrNames
                (builtins.map (key: key + suffix))
              ];
              on-failure = {
                shell = "bash";
                command = ''
                  ${pkgs.curl}/bin/curl -s \
                    -H "Title: Backup Failed" \
                    -H "Priority: high" \
                    -d "Backup job ${name} has failed." \
                    ${ntfyTopic}
                '';
              };
            }))
          ];
        };
      };
      users = {
        users.backups = {
          isSystemUser = true;
          group = "backups";
          extraGroups = cfg.joinGroups;
        };
        groups.backups = {};
      };
      systemd = {
        tmpfiles.rules = [
          "d /var/lib/homelab-backups 0700 backups backups"
          "d /var/cache/homelab-backups/restic 0700 backups backups"
        ];
        services."backups-check@" = {
          description = "Backup integrity check";
          serviceConfig = {
            Type = "oneshot";
            User = sbCfg.user;
            Group = sbCfg.group;
          };
          path = [sbCfg.wrapper];
          scriptArgs = "%i";
          script = ''
            standard-backups exec -d "$1" -- check --read-data
          '';
          # We have to include `--{...}` to ensure each value is unique
          onSuccess = ["ntfy-handler@backups--%p-%i-success.service"];
          onFailure = ["ntfy-handler@backups--%p-%i-failure.service"];
        };
      };
    };
  });
}
