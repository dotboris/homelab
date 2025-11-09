{moduleWithSystem, ...}: {
  flake.modules.nixos.default = moduleWithSystem ({self', ...}: {
    lib,
    pkgs,
    config,
    utils,
    ...
  }: let
    inherit
      (lib)
      mapAttrs
      mkIf
      mkEnableOption
      mkOption
      recursiveUpdate
      types
      ;
    inherit (utils) escapeSystemdPath;
    inherit (utils.systemdUtils) unitOptions;

    cfg = config.homelab.backups;
    autoresticCfg = config.services.autorestic;
    backendKeys = builtins.attrNames autoresticCfg.settings.backends;

    ntfyTopic = "https://${config.homelab.reverseProxy.vhosts.ntfy.fqdn}/backups";
    notifyFailure = pkgs.writeShellScript "notify-backup-failure.sh" ''
      ${pkgs.curl}/bin/curl -s \
        -H "Title: Backup Failed" \
        -H "Priority: high" \
        -d "Backup of location $AUTORESTIC_LOCATION has failed." \
        ${ntfyTopic}'';
  in {
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
      checkAt = unitOptions.stage2ServiceOptions.options.startAt;
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
                    failure = ["${notifyFailure}"];
                  };
                }
                value
            )
            cfg.locations;
        };
        check = {
          enable = true;
          startAt = cfg.checkAt;
          readData = true;
          onSuccess = [
            "ntfy-send@${escapeSystemdPath (builtins.toJSON {
              topic = "backups";
              priority = 2;
              title = "Backup Checks OK";
              message = "Backups integrity checks have completed successfully";
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

      services.standard-backups = {
        enable = true;
        user = "backups";
        group = "backups";
        extraPackages = [
          self'.packages.standard-backups-restic-backend
        ];
      };
      users = {
        users.${autoresticCfg.user}.extraGroups = cfg.joinGroups;
        groups.backups = {};
        users.backups = {
          isSystemUser = true;
          group = "backups";
          extraGroups = cfg.joinGroups;
        };
      };
    };
  });
}
