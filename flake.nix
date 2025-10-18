{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
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
    nixpkgs-unstable,
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
        _module.args.pkgs = let
          pkgsUnstable = import nixpkgs-unstable {
            inherit system;
          };
        in
          import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "netdata" # The UI is non OSS. It's under its own funny license.
              ];
            overlays = [
              # Use unstable coredns. It's supports ordering plugins correctly
              (prev: final: {
                inherit (pkgsUnstable) coredns;
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
