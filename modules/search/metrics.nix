{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.homelab.search;
  in {
    config = {
      # Not sure why this password is that important
      services.searx.settings.general.open_metrics = "supersecret";
      homelab.monitoring.netdata.prometheusConfig = {
        jobs = [
          {
            name = "searx";
            url = "http://localhost:${builtins.toString cfg.port}/metrics";
            username = "bogus";
            password = "supersecret";
          }
        ];
      };
    };
  };
}
