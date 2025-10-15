{...}: {
  flake.modules.nixos.default = {config, ...}: let
    freshrssCfg = config.services.freshrss;
  in {
    config = {
      homelab.backups = {
        locations.freshrss = {
          from = freshrssCfg.dataDir;
        };
        joinGroups = ["freshrss"];
      };
    };
  };
}
