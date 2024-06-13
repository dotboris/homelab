{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.life-management;
in {
  options = {
    homelab.life-management = {
      enable = lib.mkEnableOption "life management";
      host = lib.mkOption {type = lib.types.str;};
      port = lib.mkOption {type = lib.types.number;};
    };
  };

  config = lib.mkIf cfg.enable {
    services.monica = {
      enable = true;
      hostname = cfg.host;
      port = cfg.port;
    };
  };
}
