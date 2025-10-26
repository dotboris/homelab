{moduleWithSystem, ...}: {
  flake.modules.nixos.default = moduleWithSystem ({self', ...}: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.standard-backups;
  in {
    options.services.standard-backups = {
      enable = lib.mkEnableOption "standard-backup";
      package = lib.mkPackageOption self'.packages "standard-backups" {};
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = ''
          Additional packages to make available to `standard-backups`. This is
          where you include packages holding backends and recipes.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      environment = {
        systemPackages = [cfg.package] ++ cfg.extraPackages;
        pathsToLink = ["/share/standard-backups"];
        etc."standard-backups/config.yaml" = {
          source = let
            yaml = pkgs.formats.yaml {};
          in
            yaml.generate "standard-backups-config" {
              version = 1;
            };
        };
      };
    };
  });
}
