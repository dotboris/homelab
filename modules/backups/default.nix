{moduleWithSystem, ...}: {
  flake.modules.nixos.default = moduleWithSystem ({self', ...}: {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.homelab.backups;
    sbCfg = config.services.standard-backups;
    destinationKeys = builtins.attrNames sbCfg.settings.destinations;
    ntfyTopic = "https://${config.homelab.reverseProxy.vhosts.ntfy.fqdn}/backups";
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
      # Copied from `services.standard-backups.jobSchedules` for convenience
      jobSchedules = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          When to run the different backup jobs. Key is the job name,
          value is a string who's format is described by systemd.time(7)
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
                keep-last = config.last;
                keep-daily = config.daily;
                keep-weekly = config.weekly;
                keep-monthly = config.monthly;
                keep-yearly = config.yearly;
              };
            };
          };
        }));
        default = {};
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
        inherit (cfg) jobSchedules;
        enable = true;
        user = "backups";
        group = "backups";
        extraPackages =
          [self'.packages.standard-backups-restic-backend]
          ++ (builtins.attrValues cfg.recipes);
        settings.jobs =
          lib.mapAttrs (name: _: {
            recipe = name;
            backup-to = destinationKeys;
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
