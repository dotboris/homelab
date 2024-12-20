{
  lib,
  config,
  ...
}: let
  inherit (lib) types mkOption;
  cfg = config.homelab.reverseProxy;
in {
  options = {
    homelab.reverseProxy = {
      baseDomain = mkOption {
        type = types.str;
      };
      vhostSuffix = mkOption {
        type = types.str;
        default = "";
      };
      vhosts = mkOption {
        type = types.attrsOf (
          types.submodule ({config, ...}: {
            options = {
              fqdn = mkOption {
                type = types.str;
                internal = true;
              };
            };
            config.fqdn = "${config._module.args.name}${cfg.vhostSuffix}.${cfg.baseDomain}";
          })
        );
      };
    };
  };
}
