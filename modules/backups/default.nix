{
  lib,
  pkgs,
  config,
  utils,
  ...
}:
with utils;
with lib; let
  cfg = config.homelab.backups;
  autoresticCfg = config.services.autorestic;
  backendKeys = builtins.attrNames autoresticCfg.settings.backends;

  ntfyTopic = "https://${config.homelab.reverseProxy.vhosts.ntfy.fqdn}/backups";
  notifySuccess = pkgs.writeShellScript "notify-backup-success.sh" ''
    ${pkgs.curl}/bin/curl -s \
      -H "Title: Backup Complete" \
      -H "Priority: low" \
      -d "Backup of location $AUTORESTIC_LOCATION has completed sucessfully." \
      ${ntfyTopic}'';
  notifyFailure = pkgs.writeShellScript "notify-backup-failure.sh" ''
    ${pkgs.curl}/bin/curl -s \
      -H "Title: Backup Failed" \
      -H "Priority: high" \
      -d "Backup of location $AUTORESTIC_LOCATION has failed." \
      ${ntfyTopic}'';
in {
  imports = [
    ./backends/local.nix
    ./backends/backblaze.nix
    ./github.nix
  ];

  options.homelab.backups = {
    enable = mkEnableOption "homelab backups";
    locations = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };
    joinGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of groups to join the backup user to. This is useful to give the
        backup user access to files they normally wouldn't have access to.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.autorestic = {
      enable = true;
      settings = {
        version = 2;
        global.forget = {
          keep-last = 4; # Assuming 4 backups a day, that keeps them all
          keep-daily = 7;
          keep-weekly = 4;
          keep-monthly = 12;
          keep-yearly = 7;
        };
        locations =
          mapAttrs (
            _: value:
              recursiveUpdate {
                to = backendKeys;
                forget = "yes";
                hooks = {
                  success = ["${notifySuccess}"];
                  failure = ["${notifyFailure}"];
                };
              }
              value
          )
          cfg.locations;
      };
      check = {
        enable = true;
        interval = "monthly";
        readData = true;
        onSuccess = [
          "ntfy-send@${escapeSystemdPath (builtins.toJSON {
            topic = "backups";
            priority = 2;
            title = "Backup Checks OK";
            message = "Backups integrity checks have completed succesfully";
          })}.service"
        ];
        onFailure = [
          "ntfy-send@${escapeSystemdPath (builtins.toJSON {
            topic = "backups";
            priority = 5;
            title = "Backup Checks Failed";
            message = "Backups integrity checks have failed";
          })}.service"
        ];
      };
    };

    users.users.${autoresticCfg.user}.extraGroups = cfg.joinGroups;
  };
}
