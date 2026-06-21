{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.backups.destinations.backblaze;
  in {
    options.homelab.backups.destinations.backblaze = {
      enable = lib.mkEnableOption "homelab backups backblaze backend";
      region = lib.mkOption {
        type = lib.types.str;
      };
      bucketName = lib.mkOption {
        type = lib.types.str;
      };
      checkAt = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          When to check the integrity of the backblaze destination. Integrity
          checks only run when this is set.
        '';
      };
    };
    config = lib.mkIf cfg.enable {
      sops.secrets = {
        "backups/repos/backblaze/password" = {
          owner = "backups";
        };
        "backups/repos/backblaze/keyId" = {
          owner = "backups";
        };
        "backups/repos/backblaze/key" = {
          owner = "backups";
        };
      };
      systemd.timers.backups-check-backblaze = lib.mkIf (cfg.checkAt != null) {
        wantedBy = ["timers.target"];
        timerConfig = {
          Unit = "backups-check@backblaze.service";
          OnCalendar = cfg.checkAt;
        };
      };

      services.standard-backups.settings.secrets = {
        backblazePassword.from-file = config.sops.secrets."backups/repos/backblaze/password".path;
        backblazeKeyId.from-file = config.sops.secrets."backups/repos/backblaze/keyId".path;
        backblazeKey.from-file = config.sops.secrets."backups/repos/backblaze/key".path;
      };
      homelab.backups._destinations.backblaze.options = {
        # We use the Backblaze's S3 compatible API instead of the regular B2 API
        # because the lib that restic uses under the hood for B2 doesn't do error
        # handling too well. While this is a little odd, it's for the better.
        repo = "s3:https://s3.${cfg.region}.backblazeb2.com/${cfg.bucketName}";
        env = {
          RESTIC_CACHE_DIR = "/var/cache/homelab-backups/restic";
          RESTIC_PASSWORD = "{{ .Secrets.backblazePassword }}";
          AWS_ACCESS_KEY_ID = "{{ .Secrets.backblazeKeyId }}";
          AWS_SECRET_ACCESS_KEY = "{{ .Secrets.backblazeKey }}";
        };
      };
    };
  };
}
