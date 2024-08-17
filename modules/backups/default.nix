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
        locations = mapAttrs (_: value: value // {to = ["local"];}) cfg.locations;
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
