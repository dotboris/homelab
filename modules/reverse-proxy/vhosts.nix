{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.reverseProxy;
  vhostType = lib.types.submodule ({config, ...}: {
    options = {
      fqdn = lib.mkOption {
        type = lib.types.str;
        default = "${config._module.args.name}${cfg.vhostSuffix}.${cfg.baseDomain}";
      };
    };
  });
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
        type = lib.types.attrsOf vhostType;
      };
    };
  };
}
