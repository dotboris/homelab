{self, ...}: {
  flake.modules.nixos.default = {
    pkgs,
    config,
    ...
  }: let
    freshrssCfg = config.services.freshrss;
  in {
    config = {
      homelab.backups = {
        locations.freshrss = {
          from = freshrssCfg.dataDir;
        };
        recipes.freshrss = self.lib.mkBackupRecipe pkgs {
          name = "freshrss";
          paths = [freshrssCfg.dataDir];
        };
        joinGroups = ["freshrss"];
      };
    };
  };
}
