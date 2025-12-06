{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.homelab.monitoring.netdata;
    yaml = pkgs.formats.yaml {};
  in {
    options.homelab.monitoring.netdata.prometheusConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        content of `go.d/prometheus.conf`
      '';
    };
    config = {
      # Sometimes there's a race condition on boot so we retry to make sure we pick it up
      homelab.monitoring.netdata.prometheusConfig.autodetection_retry = lib.mkDefault 30;
      services.netdata.configDir."go.d/prometheus.conf" =
        lib.mkIf (cfg.prometheusConfig != {})
        (yaml.generate "prometheus.conf" cfg.prometheusConfig);
    };
  };
}
