{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.backups.backends.backblaze;
  autoresticCfg = config.services.autorestic;
in {
  options.homelab.backups.backends.backblaze = {
    enable = mkEnableOption "homelab backend backblaze backend";
  };
  config = mkIf cfg.enable {
    sops = let
      password = "backups/repos/backblaze/password";
      keyId = "backups/repos/backblaze/keyId";
      key = "backups/repos/backblaze/key";
    in {
      secrets = {
        ${password} = {};
        ${keyId} = {};
        ${key} = {};
      };
      templates."homelab-backups-backblaze-backend.env" = {
        owner = autoresticCfg.user;
        content = ''
          AUTORESTIC_BACKBLAZE_RESTIC_PASSWORD=${config.sops.placeholder.${password}}
          AUTORESTIC_BACKBLAZE_B2_ACCOUNT_ID=${config.sops.placeholder.${keyId}}
          AUTORESTIC_BACKBLAZE_B2_ACCOUNT_KEY=${config.sops.placeholder.${key}}
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.path} 0700 ${autoresticCfg.user} ${autoresticCfg.group}"
    ];
    services.autorestic = {
      environmentFiles = [config.sops.templates."homelab-backups-backblaze-backend.env".path];
      settings = {
        backends.backblaze = {
          type = "b2";
        };
      };
    };
  };
}
