{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    netdataCfg = config.services.netdata;
    redisCfg = config.services.redis;
    yaml = pkgs.formats.yaml {};
  in {
    config = lib.mkIf (redisCfg.servers != {}) {
      # Grant netdata access to connect
      users.users.${netdataCfg.user}.extraGroups =
        lib.mapAttrsToList (_: server: server.group) redisCfg.servers;
      services.netdata.configDir."go.d/redis.conf" = yaml.generate "redis.conf" {
        update_every = 1;
        autodetection_retry = 0;
        jobs =
          lib.mapAttrsToList (name: server: {
            inherit name;
            address = "unix://@${server.unixSocket}";
          })
          redisCfg.servers;
      };
    };
  };
}
