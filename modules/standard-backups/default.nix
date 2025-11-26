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
  in {
    options.services.standard-backups = {
      enable = lib.mkEnableOption "standard-backups";
      package = lib.mkPackageOption self'.packages "standard-backups" {};
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = ''
          Additional packages to make available to `standard-backups`. This is
          where you include packages holding backends and recipes.
        '';
      };
      wrapper = lib.mkOption {
        type = lib.types.package;
        description = ''
          Wrapper program around `standard-backups` that sets all environment
          variables correctly and runs as the right user / group.  This is set
          automatically and is meant to help you call `standard-backups` in
          your own systemd units.
        '';
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
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
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          When to run the different `standard-backups` jobs. Key is the job name
          value is a string who's format is described by systemd.time(7)
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.standard-backups = {
        settings.version = 1;
        wrapper = pkgs.writeShellApplication {
          name = "standard-backups";
          runtimeInputs =
            [
              cfg.package
              pkgs.bash # to run hooks
            ]
            ++ cfg.extraPackages;
          runtimeEnv.XDG_DATA_DIRS = lib.makeSearchPath "share" ([cfg.package] ++ cfg.extraPackages);
          text = ''
            run="exec"
            if [[ "$USER" != "${lib.escapeShellArg cfg.user}" ]]; then
            ${
              if config.security.sudo.enable
              then "run='exec ${config.security.wrapperDir}/sudo -u ${cfg.user} -E'"
              else ">&2 echo 'Aborting, standard-backups must be run as user `${cfg.user}`!'; exit 2"
            }
            fi
            $run ${lib.getExe cfg.package} "$@"
          '';
        };
      };
      environment = {
        systemPackages = [cfg.wrapper];
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
        path = [cfg.wrapper];
        scriptArgs = "%i";
        script = ''standard-backups backup "$1"'';
      };
      systemd.timers =
        lib.mapAttrs' (
          job: startTime:
            lib.nameValuePair "standard-backups-${job}" {
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
