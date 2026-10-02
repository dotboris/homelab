{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.code;
    forgejoCfg = config.services.forgejo;
    wrapper =
      pkgs.runCommand "forgejo-cli-wrapper" {
        nativeBuildInputs = [
          pkgs.makeWrapper
        ];
      } ''
        makeWrapper ${lib.getExe forgejoCfg.package} $out/bin/forgejo \
          --add-flags '--config ${forgejoCfg.customDir}/conf/app.ini'
      '';
  in {
    config = lib.mkIf cfg.enable {
      users.users.${forgejoCfg.user}.packages = [wrapper];
    };
  };
}
