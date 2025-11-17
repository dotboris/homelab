{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }:
    with lib; let
      cfg = config.homelab.backups.destinations.backblaze;
      sbCfg = config.services.standard-backups;
    in {
      options.homelab.backups.destinations.backblaze = {
        enable = mkEnableOption "homelab backups backblaze backend";
        bucketName = mkOption {
          type = types.str;
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
      config = mkIf cfg.enable {
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
        systemd.services.backups-check-backblaze-destination = {
          description = "Check integrity of the backblaze backup destination";
          serviceConfig = {
            Type = "oneshot";
            User = sbCfg.user;
            Group = sbCfg.group;
          };
          path = [sbCfg.wrapper];
          script = ''
            standard-backups exec -d backblaze -- check --read-data
          '';
          startAt = lib.mkIf (cfg.checkAt != null) cfg.checkAt;
        };
        services.standard-backups.settings = {
          secrets = {
            backblazePassword.from-file = config.sops.secrets."backups/repos/backblaze/password".path;
            backblazeKeyId.from-file = config.sops.secrets."backups/repos/backblaze/keyId".path;
            backblazeKey.from-file = config.sops.secrets."backups/repos/backblaze/key".path;
          };
          destinations.backblaze = self.lib.mkResticDestination {
            options = {
              repo = "b2:${cfg.bucketName}";
              env = {
                RESTIC_PASSWORD = "{{ .Secrets.backblazePassword }}";
                B2_ACCOUNT_ID = "{{ .Secrets.backblazeKeyId }}";
                B2_ACCOUNT_KEY = "{{ .Secrets.backblazeKey }}";
              };
            };
          };
        };
      };
    };
}
