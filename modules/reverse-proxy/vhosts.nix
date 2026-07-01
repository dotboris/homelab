{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    ...
  }: let
    cfg = config.homelab.reverseProxy;
  in {
    options = {
      homelab.reverseProxy = {
        baseDomain = lib.mkOption {
          type = lib.types.str;
        };
        vhostSuffix = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        vhosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule ({config, ...}: {
              options = {
                fqdn = lib.mkOption {
                  type = lib.types.str;
                  internal = true;
                };
                nameWithSuffix = lib.mkOption {
                  type = lib.types.str;
                  internal = true;
                };
              };
              config = rec {
                nameWithSuffix = "${config._module.args.name}${cfg.vhostSuffix}";
                fqdn = "${nameWithSuffix}.${cfg.baseDomain}";
              };
            })
          );
        };
      };
    };
  };
}
