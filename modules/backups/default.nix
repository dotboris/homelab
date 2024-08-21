{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.backups;
  autoresticCfg = config.services.autorestic;
  locationKeys = builtins.attrNames cfg.locations;
in {
  imports = [
    ./backends/local.nix
    ./backends/backblaze.nix
  ];

  options.homelab.backups = {
    enable = mkEnableOption "homelab backups";
    locations = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };
    reposDir = mkOption {
      type = types.str;
      default = "/var/lib/homelab-backups/repos";
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
    # sops = {
    #   secrets = {
    #     "backups/repos/b2/password" = mkIf cfg.enableB2Backend {};
    #     "backups/repos/b2/keyId" = mkIf cfg.enableB2Backend {};
    #     "backups/repos/b2/key" = mkIf cfg.enableB2Backend {};
    #   };
    #   templates."autorestic.env" = {
    #     owner = autoresticCfg.user;
    #     content = ''
    #       AUTORESTIC_B2_RESTIC_PASSWORD=${config.sops.placeholder."backups/repos/b2/password"}
    #       AUTORESTIC_B2_ACCOUNT_ID=${config.sops.placeholder."backups/repos/b2/keyId"}
    #       AUTORESTIC_B2_ACCOUNT_KEY=${config.sops.placeholder."backups/repos/b2/key"}
    #     '';
    #   };
    # };

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
        locations = mapAttrs (_: value:
          value
          // {
            to = locationKeys;
            forget = "yes";
          })
        cfg.locations;
      };
    };

    users.users.${autoresticCfg.user}.extraGroups = cfg.joinGroups;
  };
}
