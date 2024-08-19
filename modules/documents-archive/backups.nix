{
  pkgs,
  config,
  ...
}: let
  autoresticCfg = config.services.autorestic;
  exportDir = "/var/lib/paperless-export";
  paperlessManage = "/var/lib/paperless/paperless-manage";
  exportScript =
    pkgs.writeShellScript "paperless-export-for-backups"
    ''
      set -euo pipefail
      umask 037
      echo exporting
      ${paperlessManage} document_exporter --split-manifest ${exportDir}
      echo fixing permissions
      find ${exportDir} -type f -exec chmod 640 '{}' +
      find ${exportDir} -type d -exec chmod 750 '{}' +
    '';
in {
  config = {
    systemd.tmpfiles.rules = [
      "d ${exportDir} 0750 paperless ${autoresticCfg.group}"
    ];
    security.sudo.extraRules = [
      {
        users = [autoresticCfg.user];
        runAs = "paperless:${autoresticCfg.group}";
        commands = [
          {
            command = "${exportScript}";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    homelab.backups.locations.paperless = {
      hooks.before = [
        "/run/wrappers/bin/sudo -u paperless -g ${autoresticCfg.group} ${exportScript}"
      ];
      from = exportDir;
    };
  };
}
