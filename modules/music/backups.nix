{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.homelab.music;
  in {
    homelab.backups = {
      recipes.music = self.lib.mkBackupRecipe pkgs {
        name = "music";
        paths = [cfg.musicDir];
        exclude = [".hist"];
      };
      joinGroups = ["music"];
    };
  };
}
