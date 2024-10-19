{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
with utils;
with lib; let
  cfg = config.services.autorestic;
  script = concatStringsSep " " ([
      "autorestic"
      "exec"
      "--all"
      "--verbose"
      "--ci"
      "--config"
      "${cfg.stateDir}/autorestic.yml"
      "--"
      "check"
    ]
    ++ (optional cfg.check.readData "--read-data"));
in {
  options.services.autorestic.check = {
    inherit (systemdUtils.unitOptions.commonUnitOptions.options) onSuccess onFailure;
    enable = mkEnableOption "autorestic periodic check";
    interval = mkOption {
      type = types.str;
      example = "daily";
      description = ''
        How often to run `autorestic check`.

        The format is described in systemd.time(7).
      '';
    };
    readData = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Runs `restic check` in the `--read-data` flag.
        This makes restic download all data to validate its integrity.
      '';
    };
  };
  config = mkIf cfg.check.enable {
    systemd = {
      services.autorestic-check = {
        inherit (cfg.check) onSuccess onFailure;
        inherit script;
        description = "autorestic check";
        path = [
          cfg.package
          pkgs.restic # autorestic runs restic to do backups
        ];
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = cfg.environmentFiles;
        };
      };
      timers.autorestic-check = {
        description = "Timer for autorestic check";
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = cfg.check.interval;
      };
    };
  };
}
