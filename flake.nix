{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixos-images = {
      url = "github:nix-community/nixos-images";
      inputs = {
        nixos-unstable.follows = "nixpkgs";
        nixos-stable.follows = "nixpkgs";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixos-stable.follows = "nixpkgs";
        nixos-images.follows = "nixos-images";
        flake-parts.follows = "flake-parts";
        disko.follows = "disko";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    import-tree,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      imports = [
        flake-parts.flakeModules.modules
        (import-tree [
          ./packages
          ./modules
          ./hosts
        ])
      ];
      systems = ["x86_64-linux"];
      perSystem = {
        pkgs,
        system,
        self',
        inputs',
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "netdata" # The UI is non OSS. It's under its own funny license.
            ];
          overlays = [
            (final: prev: {
              # HACK: `nixos-images` is not ready for 25.11 and still references
              # the old zfsUnstable which has been removed. This works around
              # the issue until the following PR gets merged:
              # https://github.com/nix-community/nixos-images/pull/385
              zfsUnstable = prev.zfs_unstable;
            })
          ];
        };
        formatter = pkgs.writeShellApplication {
          name = "alejandra-format-repo";
          runtimeInputs = [pkgs.alejandra];
          text = "alejandra .";
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nil
            pkgs.alejandra
            pkgs.statix

            # Secrets management
            pkgs.sops
            pkgs.age
            pkgs.ssh-to-age

            # Deployment
            inputs'.nixos-anywhere.packages.default

            # standard-backups
            self'.packages.standard-backups
            self'.packages.standard-backups-restic-backend
            self'.packages.standard-backups-rsync-backend
            pkgs.restic
          ];
        };

        checks = {
          statix = pkgs.runCommand "statix" {buildInputs = [pkgs.statix];} ''
            statix check -c ${./statix.toml} ${./.}
            touch $out
          '';
        };
      };
    });
}
