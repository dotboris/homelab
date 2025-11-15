{lib, ...}: {
  flake.lib = {
    mkResticDestination = options:
      lib.recursiveUpdate options {
        backend = "restic";
        options.forget = {
          enable = true;
          options = {
            keep-last = 4; # Assuming 4 backups a day, that keeps them all
            keep-daily = 7;
            keep-weekly = 4;
            keep-monthly = 12;
            keep-yearly = 7;
          };
        };
      };
    mkBackupRecipe = pkgs: options:
      pkgs.writeTextDir
      "share/standard-backups/recipes/${options.name}.yaml"
      (builtins.toJSON (lib.recursiveUpdate options {
        version = 1;
      }));
  };
}
