{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.backups;
  autoresticCfg = config.services.autorestic;
  stateDir = "/var/lib/homelab-backups";
  reposDir = "${stateDir}/repos";
in {
  options.homelab.backups = {
    enable = mkEnableOption "homelab backups";
    locations = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };
    joinGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of groups to join the backup user to. This is useful to give the
        backup user access to files they normally wouldn't have access to.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops = let
      localPass = "backups/repos/local/password";
    in {
      secrets = {
        ${localPass} = {};
      };
      templates."autorestic.env" = {
        owner = autoresticCfg.user;
        content = ''
          AUTORESTIC_LOCAL_RESTIC_PASSWORD=${config.sops.placeholder.${localPass}}
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0700 ${autoresticCfg.user} ${autoresticCfg.group}"
      "d ${reposDir} 0700 ${autoresticCfg.user} ${autoresticCfg.group}"
    ];
    services.autorestic = {
      enable = true;
      environmentFile = config.sops.templates."autorestic.env".path;
      settings = {
        version = 2;
        global.forget = {
          keep-last = 4; # Assuming 4 backups a day, that keeps them all
          keep-daily = 7;
          keep-weekly = 4;
          keep-monthly = 12;
          keep-yearly = 7;
        };
        locations = mapAttrs (_: value:
          value
          // {
            to = ["local"];
            forget = "yes";
          })
        cfg.locations;
        backends = {
          local = {
            type = "local";
            path = "${reposDir}/local";
          };
        };
      };
    };

    users.users.${autoresticCfg.user}.extraGroups = cfg.joinGroups;
  };
}
