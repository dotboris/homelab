{
  self,
  moduleWithSystem,
  ...
}: {
  flake.modules.nixos.default = self.modules.nixos.standard-backups;
  flake.modules.nixos.standard-backups = moduleWithSystem ({self', ...}: {
    config,
    lib,
    pkgs,
    utils,
    ...
  }: let
    cfg = config.services.standard-backups;
    packages = [cfg.package] ++ cfg.extraPackages;
  in {
    options.services.standard-backups = {
      enable = lib.mkEnableOption "standard-backup";
      package = lib.mkPackageOption self'.packages "standard-backups" {};
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = ''
          Additional packages to make available to `standard-backups`. This is
          where you include packages holding backends and recipes.
        '';
      };
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = ''
          Contents of the `standard-backups` configuration file (v1).
        '';
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = ''
          User to run `standard-backups` as.

          This user must already exist and will not be created for you.
        '';
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = ''
          Group to run `standard-backups` as.

          This user must already exist and will not be created for you.
        '';
      };
      jobSchedules = lib.mkOption {
        type =
          lib.types.attrsOf
          lib.types.str;
        # utils.systemdUtils.unitOptions.stage2ServiceOptions.options.startAt;
        default = {};
        description = ''
          When to run the different `standard-backups` jobs. Key is the job name
          value is a string who's format is described by systemd.time(7)
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.standard-backups.settings.version = 1;
      environment = {
        systemPackages = [cfg.package] ++ cfg.extraPackages;
        pathsToLink = ["/share/standard-backups"];
        etc."standard-backups/config.yaml" = {
          source = let
            yaml = pkgs.formats.yaml {};
          in
            yaml.generate "standard-backups-config" cfg.settings;
        };
      };
      systemd.services."standard-backups@" = {
        description = "Runs a standard-backups job";
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
        };
        # Ensure backends and recipes are discovered
        environment.XDG_DATA_DIRS = lib.makeSearchPath "share" packages;
        # Ensure backends can run
        path = packages;
        scriptArgs = "%i";
        script = ''
          standard-backups backup "$1"
        '';
      };
      systemd.timers =
        lib.mapAttrs' (
          job: startTime:
            lib.nameValuePair "standard-backup-${job}" {
              description = "Periodic backups for ${job} standard-backups job";
              wantedBy = ["timers.target"];
              timerConfig = {
                Unit = "standard-backups@${job}.service";
                OnCalendar = startTime;
              };
            }
        )
        cfg.jobSchedules;
    };
  });
}
