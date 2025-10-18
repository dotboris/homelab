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
          hostname = lib.mkOption {type = lib.types.str;};
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
        hostname = host.hostname;
        user = "root";
        sshUser = "dotboris";
        interactiveSudo = true;
        fastConnection = true;
        magicRollback = false;
        profiles.system.path = nixos self.nixosConfigurations.${name};
      }))
      config.flake.hosts;

    apps = lib.pipe config.flake.hosts [
      (lib.mapAttrsToList
        (name: host: {
          ${host.system}."deploy-${name}" = withSystem host.system ({pkgs, ...}: {
            type = "app";
            meta.description = "Deploy ${name} NixOS configuration to ${host.hostname}";
            program = pkgs.writeShellApplication {
              name = "deploy-${name}";
              runtimeInputs = [
                self.nixosConfigurations.${name}.config.system.build.nixos-rebuild
              ];
              text = ''
                nixos-rebuild switch \
                  --flake ${lib.escapeShellArg ".#${name}"} \
                  --target-host ${lib.escapeShellArg host.hostname} \
                  --use-remote-sudo \
                  --verbose \
                  --print-build-logs
              '';
            };
          });
        }))
      lib.mkMerge
    ];

    checks = lib.pipe config.flake.hosts [
      (lib.mapAttrsToList
        (name: host: {
          ${host.system}."nixos-${name}" =
            self.nixosConfigurations.${name}.config.system.build.toplevel;
        }))
      lib.mkMerge
    ];
  };
}
