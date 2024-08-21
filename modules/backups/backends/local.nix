{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.backups.backends.local;
  autoresticCfg = config.services.autorestic;
in {
  options.homelab.backups.backends.local = {
    enable = mkEnableOption "homelab backend local backend";
    path = mkOption {
      type = types.path;
      default = "/var/lib/homelab-backups/repos";
    };
  };
  config = mkIf cfg.enable {
    sops = let
      password = "backups/repos/local/password";
    in {
      secrets = {
        ${password} = {};
      };
      templates."homelab-backups-local-backend.env" = {
        owner = autoresticCfg.user;
        content = ''
          AUTORESTIC_LOCAL_RESTIC_PASSWORD=${config.sops.placeholder.${password}}
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.path} 0700 ${autoresticCfg.user} ${autoresticCfg.group}"
    ];
    services.autorestic = {
      environmentFiles = [config.sops.templates."homelab-backups-local-backend.env".path];
      settings = {
        backends.local = {
          inherit (cfg) path;
          type = "local";
        };
      };
    };
  };
}
