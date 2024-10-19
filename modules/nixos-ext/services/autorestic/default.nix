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
  resticCacheDir = "${cfg.cacheDir}/restic";
  configFile = (pkgs.formats.yaml {}).generate "autorestic-config" (
    recursiveUpdate {
      global.all.cache-dir = resticCacheDir;
    }
    cfg.settings
  );
  autoresticWrapper = pkgs.writeShellScriptBin "autorestic-wrapper" (
    ''
      set -euo pipefail
      set -a # export from .env files
    ''
    + concatMapStrings (envFile: "source ${envFile}\n") cfg.environmentFiles
    + ''
      set +a # stop exporting

      exec ${cfg.package}/bin/autorestic \
        --config ${cfg.stateDir}/autorestic.yml \
        --restic-bin ${pkgs.restic}/bin/restic \
        "$@"
    ''
  );
in {
  imports = [
    ./check.nix
  ];

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
    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/autorestic";
    };
    cacheDir = mkOption {
      type = types.path;
      default = "/var/cache/autorestic";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = mkIf createUser {
      inherit (cfg) group;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = mkIf createGroup {};

    systemd = {
      tmpfiles.rules = [
        "d ${resticCacheDir} 0700 ${cfg.user} ${cfg.group}"
        "d ${cfg.stateDir} 0755 ${cfg.user} ${cfg.group}"
        "L+ ${cfg.stateDir}/autorestic.yml - - - - ${configFile}"
        "L+ ${cfg.stateDir}/autorestic-wrapper - - - - ${autoresticWrapper}/bin/autorestic-wrapper"
      ];
      services.autorestic = {
        description = "autorestic cron handler";
        path = [
          cfg.package
          pkgs.bash # autorestic runs hooks through bash
          pkgs.restic # autorestic runs restic to do backups
        ];
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = cfg.environmentFiles;
        };
        script = ''
          autorestic cron \
            --verbose \
            --ci \
            --lean \
            --config ${cfg.stateDir}/autorestic.yml
        '';
      };
      timers.autorestic = {
        description = "Timer for autorestic cron handler";
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = cfg.interval;
      };
    };
  };
}
