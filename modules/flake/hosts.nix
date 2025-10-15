{
  config,
  self,
  inputs,
  lib,
  withSystem,
  ...
}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in {
  options.flake = {
    deploy.nodes = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.attrs;
    };
    hosts = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule {
        options = {
          system = lib.mkOption {type = lib.types.str;};
          ip = lib.mkOption {type = lib.types.str;};
          module = lib.mkOption {type = lib.types.deferredModule;};
        };
      });
      default = {};
    };
  };

  config.flake = {
    nixosConfigurations =
      lib.mapAttrs (name: host: (
        withSystem host.system ({pkgs, ...}:
          nixosSystem {
            inherit pkgs;
            inherit (host) system;
            modules = [host.module];
          })
      ))
      config.flake.hosts;

    deploy.nodes =
      lib.mapAttrs (name: host: (let
        inherit (inputs.deploy-rs.lib.${host.system}.activate) nixos;
      in {
        hostname = host.ip;
        user = "root";
        sshUser = "dotboris";
        interactiveSudo = true;
        fastConnection = true;
        magicRollback = false;
        profiles.system.path = nixos self.nixosConfigurations.${name};
      }))
      config.flake.hosts;
  };
}
