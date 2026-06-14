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
    variants = lib.mapAttrs (_: value: {forget = value._forgetOption;}) cfg.retentionProfiles;
  in {
    options.homelab.backups = {
      enable = lib.mkEnableOption "homelab backups";
      recipes = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = {};
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
      };
      defaultRetentionProfile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
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
      };
      _destinations = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
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
          destinations = lib.mkMerge [
            cfg._destinations
            (lib.mapAttrs
              (_: _: {
                inherit variants;
                backend = "restic";
                default-variant = cfg.defaultRetentionProfile;
              })
              cfg._destinations)
          ];
          jobs =
            lib.mapAttrs (name: _: {
              recipe = name;
              backup-to = let
                inherit (cfg.jobs.${name} or {retentionProfile = null;}) retentionProfile;
                suffix =
                  if retentionProfile != null
                  then "/${retentionProfile}"
                  else "";
              in
                lib.pipe cfg._destinations [
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
            })
            cfg.recipes;
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
