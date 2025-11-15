{self, ...}: {
  flake.modules.nixos.default = {
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
        bucketName = mkOption {
          type = types.str;
        };
      };
      config = mkIf cfg.enable {
        sops = let
          password = "backups/repos/backblaze/password";
          keyId = "backups/repos/backblaze/keyId";
          key = "backups/repos/backblaze/key";
        in {
          secrets = {
            ${password} = {
              owner = "backups";
            };
            ${keyId} = {
              owner = "backups";
            };
            ${key} = {
              owner = "backups";
            };
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

        services.autorestic = {
          environmentFiles = [config.sops.templates."homelab-backups-backblaze-backend.env".path];
          settings = {
            backends.backblaze = {
              type = "b2";
              path = cfg.bucketName;
            };
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
