{...}: {
  flake.modules.nixos.default = {
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
      systemd.network.wait-online.ignoredInterfaces = [
        # We're online even if tailscale is not
        config.services.tailscale.interfaceName
      ];
    };
  };
}
