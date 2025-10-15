{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    utils,
    ...
  }: let
    inherit
      (lib)
      concatStringsSep
      mkIf
      mkEnableOption
      mkOption
      optional
      types
      ;
    inherit (utils.systemdUtils) unitOptions;
    cfg = config.services.autorestic;
    script = concatStringsSep " " ([
        "autorestic"
        "exec"
        "--all"
        "--verbose"
        "--ci"
        "--config"
        "${cfg.stateDir}/autorestic.yml"
        "--"
        "check"
      ]
      ++ (optional cfg.check.readData "--read-data"));
  in {
    options.services.autorestic.check = {
      inherit (unitOptions.commonUnitOptions.options) onSuccess onFailure;
      inherit (unitOptions.stage2ServiceOptions.options) startAt;
      enable = mkEnableOption "autorestic backup integrity check";
      readData = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Runs `restic check` in the `--read-data` flag.
          This makes restic download all data to validate its integrity.
        '';
      };
    };
    config = mkIf cfg.check.enable {
      systemd = {
        services.autorestic-check = {
          inherit (cfg.check) onSuccess onFailure startAt;
          inherit script;
          description = "autorestic check";
          path = [
            cfg.package
            pkgs.restic # autorestic runs restic to do backups
          ];
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
            EnvironmentFile = cfg.environmentFiles;
          };
        };
      };
    };
  };
}
