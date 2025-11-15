{self, ...}: {
  flake.modules.nixos.default = {
    pkgs,
    config,
    ...
  }: let
    autoresticCfg = config.services.autorestic;
    exportDir = "/var/lib/paperless-export";
    exportScript = pkgs.writeShellApplication {
      name = "paperless-export-for-backups";
      runtimeInputs = [
        config.services.paperless.manage
      ];
      text = ''
        set -euo pipefail
        set -x
        cd /
        umask 037
        paperless-manage document_exporter --split-manifest ${exportDir}
        echo fixing permissions
        find ${exportDir} -type f -exec chmod 640 '{}' +
        find ${exportDir} -type d -exec chmod 750 '{}' +
      '';
    };
    exportCmd = "${exportScript}/bin/paperless-export-for-backups";
  in {
    config = {
      systemd.tmpfiles.rules = [
        "d ${exportDir} 0750 paperless backups"
      ];
      security.sudo.extraRules = [
        {
          users = [autoresticCfg.user];
          runAs = "paperless:${autoresticCfg.group}";
          commands = [
            {
              command = "${exportCmd}";
              options = ["NOPASSWD"];
            }
          ];
        }
        {
          users = ["backups"];
          runAs = "paperless:backups";
          commands = [
            {
              command = "${exportCmd}";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
      homelab.backups = {
        locations.paperless = {
          hooks.before = [
            "/run/wrappers/bin/sudo -u paperless -g backups ${exportCmd}"
          ];
          from = exportDir;
        };
        recipes.paperless = self.lib.mkBackupRecipe pkgs {
          name = "paperless";
          paths = [exportDir];
          before = {
            shell = "bash";
            command = "/run/wrappers/bin/sudo -u paperless -g backups ${exportCmd}";
          };
        };
      };
    };
  };
}
