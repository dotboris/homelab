{lib, ...}: {
  flake.lib = {
    mkBackupRecipe = pkgs: options:
      pkgs.writeTextDir
      "share/standard-backups/recipes/${options.name}.yaml"
      (builtins.toJSON (lib.recursiveUpdate options {
        version = 1;
      }));
  };
}
