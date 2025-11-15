{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf;
    inherit (config.services.nextcloud) datadir occ;
    cfg = config.homelab.nextcloud;
    autoresticCfg = config.services.autorestic;
    sudo = "/run/wrappers/bin/sudo";
    enableMaintenanceMode =
      pkgs.writeShellScript
      "nextcloud-backups-enable-maintenance"
      "${occ}/bin/nextcloud-occ maintenance:mode --on";
    disableMaintenanceMode =
      pkgs.writeShellScript
      "nextcloud-backups-disable-maintenance"
      "${occ}/bin/nextcloud-occ maintenance:mode --off";
  in {
    config = mkIf cfg.enable {
      security.sudo.extraRules = [
        {
          users = [autoresticCfg.user];
          runAs = "nextcloud:nextcloud";
          commands = [
            {
              command = toString enableMaintenanceMode;
              options = ["NOPASSWD"];
            }
            {
              command = toString disableMaintenanceMode;
              options = ["NOPASSWD"];
            }
          ];
        }
        {
          users = ["backups"];
          runAs = "nextcloud:nextcloud";
          commands = [
            {
              command = toString enableMaintenanceMode;
              options = ["NOPASSWD"];
            }
            {
              command = toString disableMaintenanceMode;
              options = ["NOPASSWD"];
            }
          ];
        }
      ];

      homelab.backups = {
        locations.nextcloud = {
          from = datadir;
          options.backup.exclude = [
            ".rnd"
          ];
          hooks = {
            before = ["${sudo} -u nextcloud -g nextcloud ${enableMaintenanceMode}"];
            after = ["${sudo} -u nextcloud -g nextcloud ${disableMaintenanceMode}"];
          };
        };
        recipes.nextcloud = self.lib.mkBackupRecipe pkgs {
          name = "nextcloud";
          paths = [datadir];
          before = {
            shell = "bash";
            command = "${sudo} -u nextcloud -g nextcloud ${enableMaintenanceMode}";
          };
          after = {
            shell = "bash";
            command = "${sudo} -u nextcloud -g nextcloud ${disableMaintenanceMode}";
          };
        };
        joinGroups = ["nextcloud"];
      };
    };
  };
}
