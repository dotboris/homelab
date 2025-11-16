{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }:
    with lib; let
      cfg = config.homelab.backups.backends.backblaze;
    in {
      options.homelab.backups.backends.backblaze = {
        enable = mkEnableOption "homelab backups backblaze backend";
        bucketName = mkOption {
          type = types.str;
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
