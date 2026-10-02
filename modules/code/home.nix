{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.code;
  in {
    config = lib.mkIf cfg.enable {
      homelab.homepage.links = [
        {
          category = "services";
          title = "Code";
          icon = "forgejo.svg";
          description = "Forgejo";
          urlVhost = "code";
        }
      ];
    };
  };
}
