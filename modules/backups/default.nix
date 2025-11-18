{moduleWithSystem, ...}: {
  flake.modules.nixos.default = moduleWithSystem ({self', ...}: {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.homelab.backups;
    sbCfg = config.services.standard-backups;
    destinationKeys = builtins.attrNames sbCfg.settings.destinations;
    ntfyTopic = "https://${config.homelab.reverseProxy.vhosts.ntfy.fqdn}/backups";
  in {
    options.homelab.backups = {
      enable = lib.mkEnableOption "homelab backups";
      recipes = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = {};
      };
      joinGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of groups to join the backup user to. This is useful to give the
          backup user access to files they normally wouldn't have access to.
        '';
      };
      # Copied from `services.standard-backups.jobSchedules` for convenience
      jobSchedules = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          When to run the different backup jobs. Key is the job name,
          value is a string who's format is described by systemd.time(7)
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.standard-backups = {
        inherit (cfg) jobSchedules;
        enable = true;
        user = "backups";
        group = "backups";
        extraPackages =
          [self'.packages.standard-backups-restic-backend]
          ++ (builtins.attrValues cfg.recipes);
        settings.jobs =
          lib.mapAttrs (name: _: {
            recipe = name;
            backup-to = destinationKeys;
            on-failure = {
              shell = "bash";
              command = ''
                ${pkgs.curl}/bin/curl -s \
                  -H "Title: Backup Failed" \
                  -H "Priority: high" \
                  -d "Backup job ${name} has failed." \
                  ${ntfyTopic}
              '';
            };
          })
          cfg.recipes;
      };
      users = {
        users.backups = {
          isSystemUser = true;
          group = "backups";
          extraGroups = cfg.joinGroups;
        };
        groups.backups = {};
      };
      systemd.services."backups-check@" = {
        description = "Backup integrity check";
        serviceConfig = {
          Type = "oneshot";
          User = sbCfg.user;
          Group = sbCfg.group;
        };
        path = [sbCfg.wrapper];
        scriptArgs = "%i";
        script = ''
          standard-backups exec -d "$1" -- check --read-data
        '';
        # We have to include `--{...}` to ensure each value is unique
        onSuccess = ["ntfy-handler@backups--%p-%i-success.service"];
        onFailure = ["ntfy-handler@backups--%p-%i-failure.service"];
      };
    };
  });
}
