{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }:
    with lib; let
      cfg = config.homelab.backups.destinations.local;
      sbCfg = config.services.standard-backups;
    in {
      options.homelab.backups.destinations.local = {
        enable = mkEnableOption "homelab backend local backend";
        path = mkOption {
          type = types.path;
          default = "/var/lib/homelab-backups/repos/local";
        };
        checkAt = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            When to check the integrity of the local destination. Integrity
            checks only run when this is set.
          '';
        };
      };
      config = mkIf cfg.enable {
        sops.secrets."backups/repos/local/password" = {
          owner = "backups";
        };
        systemd = {
          tmpfiles.rules = [
            "d ${cfg.path} 0700 backups backups"
          ];
          services.backups-check-local-destination = {
            description = "Check integrity of the local backup destination";
            serviceConfig = {
              Type = "oneshot";
              User = sbCfg.user;
              Group = sbCfg.group;
            };
            path = [sbCfg.wrapper];
            script = ''
              standard-backups exec -d local -- check --read-data
            '';
            startAt = lib.mkIf (cfg.checkAt != null) cfg.checkAt;
          };
        };
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
