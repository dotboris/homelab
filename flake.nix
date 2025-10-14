{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    disko,
    deploy-rs,
    nixpkgs,
    nixpkgs-unstable,
    sops-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      imports = [
        (import-tree [
          ./packages
        ])
      ];
      flake = {
        nixosModules.default = {...}: {
          imports = [
            ./modules/nixos-ext
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules/dns
            ./modules/documents-archive
            ./modules/backups
            ./modules/feeds
            ./modules/home-page
            ./modules/monitoring
            ./modules/nextcloud
            ./modules/remote-access
            ./modules/reverse-proxy
            ./modules/system
          ];
        };
        nixosConfigurations = {
          homelab = withSystem "x86_64-linux" ({
            pkgs,
            system,
            ...
          }:
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = {inherit inputs;};
              modules = [
                self.nixosModules.default
                ./hosts/homelab/configuration.nix
              ];
            });
          homelab-test = withSystem "x86_64-linux" ({
            pkgs,
            system,
            ...
          }:
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = {inherit inputs;};
              modules = [
                self.nixosModules.default
                ./hosts/homelab-test/configuration.nix
              ];
            });
          homelab-test-foxtrot = withSystem "x86_64-linux" ({
            pkgs,
            system,
            ...
          }:
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = {inherit inputs;};
              modules = [
                self.nixosModules.default
                ./hosts/homelab-test-foxtrot/configuration.nix
              ];
            });
        };

        deploy.nodes = let
          inherit (deploy-rs.lib.x86_64-linux.activate) nixos;
        in {
          homelab = {
            hostname = "10.0.42.2";
            user = "root";
            sshUser = "dotboris";
            interactiveSudo = true;
            fastConnection = true;
            magicRollback = false;
            profiles.system.path = nixos self.nixosConfigurations.homelab;
          };
          homelab-test = {
            hostname = "10.0.42.3";
            user = "root";
            sshUser = "dotboris";
            interactiveSudo = true;
            fastConnection = true;
            magicRollback = false;
            profiles.system.path = nixos self.nixosConfigurations.homelab-test;
          };
          homelab-test-foxtrot = {
            hostname = "192.168.122.3";
            user = "root";
            sshUser = "dotboris";
            interactiveSudo = true;
            fastConnection = true;
            magicRollback = false;
            profiles.system.path = nixos self.nixosConfigurations.homelab-test-foxtrot;
          };
        };
      };
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
            inputs'.deploy-rs.packages.default
          ];
        };

        checks = let
          inherit (pkgs.lib.attrsets) nameValuePair mapAttrs';
          buildAll = {
            prefix,
            output,
            mapFn ? (x: x),
          }:
            mapAttrs' (name: value: nameValuePair "${prefix}${name}" (mapFn value)) output;
          runTest = path:
            pkgs.testers.runNixOSTest {
              imports = [path];
              node.specialArgs = {inherit inputs;};
            };
        in
          {
            statix = pkgs.runCommand "statix" {buildInputs = [pkgs.statix];} ''
              statix check -c ${./statix.toml} ${./.}
              touch $out
            '';
            test-dns = runTest ./modules/dns/test.nix;
          }
          # Build all packages
          // buildAll {
            prefix = "build-pkg-";
            output = self'.packages;
          }
          # Build all nixos configs
          // buildAll {
            prefix = "build-nixos-";
            output = self.nixosConfigurations;
            mapFn = host: host.config.system.build.toplevel;
          }
          # Checks from deploy-rs
          // deploy-rs.lib.${system}.deployChecks self.deploy;
      };
    });
}
