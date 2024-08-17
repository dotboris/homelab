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
  };

  config = mkIf cfg.enable {
    sops = let
      localPass = "backups/repo-passwords/local";
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
          keep-hourly = 5;
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
  };
}
