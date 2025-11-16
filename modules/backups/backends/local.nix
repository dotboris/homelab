{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }:
    with lib; let
      cfg = config.homelab.backups.backends.local;
    in {
      options.homelab.backups.backends.local = {
        enable = mkEnableOption "homelab backend local backend";
        path = mkOption {
          type = types.path;
          default = "/var/lib/homelab-backups/repos/local";
        };
      };
      config = mkIf cfg.enable {
        sops.secrets."backups/repos/local/password" = {
          owner = "backups";
        };
        systemd.tmpfiles.rules = [
          "d ${cfg.path} 0700 backups backups"
        ];
        services.standard-backups.settings = {
          secrets.localPassword.from-file = config.sops.secrets."backups/repos/local/password".path;
          destinations.local = self.lib.mkResticDestination {
            options = {
              repo = cfg.path;
              env.RESTIC_PASSWORD = "{{ .Secrets.localPassword }}";
            };
          };
        };
      };
    };
}
