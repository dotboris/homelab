{...}: {
  flake.modules.nixos.default = {pkgs, ...}: let
    yaml = pkgs.formats.yaml {};
  in {
    services.netdata = {
      extraNdsudoPackages = [
        pkgs.smartmontools # provides smartctl
      ];
      configDir."go.d/smartctl.conf" = yaml.generate "smartctl.conf" {
        update_every = 1;
        autodetection_retry = 0;
        jobs = [
          {
            name = "startctl";
            devices_poll_interval = 60;
          }
        ];
      };
    };
  };
}
