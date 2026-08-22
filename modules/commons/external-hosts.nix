{...}: {
  flake.modules.nixos.default = {
    homelab.externalHosts.pixie = {
      defaultNode = "pixie1";
      nodes = {
        pixie1 = {
          localIp = "10.0.42.4";
        };
      };
    };
  };
}
