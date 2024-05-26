{config, ...}: {
  sops.secrets."networking/wireless/env" = {};
  networking = {
    wireless = {
      enable = true;
      environmentFile = config.sops.secrets."networking/wireless/env".path;
      networks = {
        romeo = {psk = "@romeo_psk@";};
      };
    };
  };
}
