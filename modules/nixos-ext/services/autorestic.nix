{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.autorestic;
  createUser = cfg.user == "autorestic";
  createGroup = cfg.group == "autorestic";
  configFile = (pkgs.formats.yaml {}).generate "autorestic-config" cfg.settings;
in {
  options.services.autorestic = {
    enable = mkEnableOption "autorestic";
    package = mkPackageOption pkgs "autorestic" {};
    user = mkOption {
      type = types.str;
      default = "autorestic";
    };
    group = mkOption {
      type = types.str;
      default = "autorestic";
    };
    interval = mkOption {
      type = types.str;
      default = "*:0/5";
      example = "hourly";
      description = ''
        How often to run autorestic. Note that the actual backup jobs will run
        depending on the cron option in the settings.
        Defaults to every 5 minutes.

        The format is described in systemd.time(7).
      '';
    };
    settings = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };
    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = mkIf createUser {
      inherit (cfg) group;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = mkIf createGroup {};

    systemd = let
      path = [
        pkgs.autorestic
        pkgs.bash # autorestic runs hooks through bash
        pkgs.restic # autorestic runs restic to do backups
      ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "autorestic";
        EnvironmentFile = cfg.environmentFiles;
      };
      preStart = ''
        echo "Preparing autorestic config"
        ln -sf ${configFile} "$STATE_DIRECTORY/autorestic.yml"
        echo "Running autorestic check"
        autorestic check \
          --verbose \
          --ci \
          --config $STATE_DIRECTORY/autorestic.yml
      '';
    in {
      services.autorestic = {
        inherit path serviceConfig preStart;
        description = "autorestic cron handler";
        script = ''
          echo "Running autorestic cron"
          autorestic cron \
            --verbose \
            --ci \
            --lean \
            --config $STATE_DIRECTORY/autorestic.yml
        '';
      };
      timers.autorestic = {
        description = "Timer for autorestic cron handler";
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = cfg.interval;
      };
      services.autorestic-backup-all = {
        inherit path serviceConfig preStart;
        description = "manually backup all locations managed by autorestic";
        script = ''
          echo "Running autorestic backup"
          autorestic backup \
            --all \
            --verbose \
            --ci \
            --config $STATE_DIRECTORY/autorestic.yml
        '';
      };
    };
  };
}
