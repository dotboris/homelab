{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.homelab.remote-access;
in {
  options.homelab.remote-access = {
    enable = mkEnableOption "Remote access";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      disableTaildrop = true;
    };
  };
}
