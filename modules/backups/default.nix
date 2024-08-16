{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.backups;
in {
  options.homelab.backups = {
    enable = mkEnableOption "homelab backups";
  };

  config = mkIf cfg.enable {
    services.autorestic.enable = true;
  };
}
