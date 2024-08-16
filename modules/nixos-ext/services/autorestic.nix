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
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = mkIf createUser {
      inherit (cfg) group;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = mkIf createGroup {};

    systemd = {
      services.autorestic = {
        description = "autorestic cron handler";
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;
          RuntimeDirectory = "autorestic";
        };
        preStart = ''
          ln -s ${configFile} "$RUNTIME_DIRECTORY/autorestic.yml"
        '';
        script = ''
          ${cfg.package}/bin/autorestic cron \
            --ci \
            --config $RUNTIME_DIRECTORY/autorestic.yml
        '';
      };
      timers.autorestic = {
        description = "Timer for autorestic cron handler";
        partOf = ["autorestic.service"];
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = cfg.interval;
      };
    };
  };
}
