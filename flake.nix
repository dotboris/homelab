{
  description = "Home Lab / Home Server";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixos-images = {
      url = "github:nix-community/nixos-images";
      inputs = {
        nixos-unstable.follows = "nixpkgs";
        nixos-2311.follows = "nixpkgs";
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
    disko,
    deploy-rs,
    nixpkgs,
    nixos-anywhere,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    callPackage = path: overrides: pkgs.callPackage path {inherit inputs;} // overrides;
  in {
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.statix

        # Secrets management
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age

        # Deployment
        nixos-anywhere.packages.${system}.default
        deploy-rs.packages.${system}.default
      ];
    };

    nixosModules.default = {...}: {
      imports = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./modules/adblock
        ./modules/feeds
        ./modules/home-page
        ./modules/monitoring
        ./modules/reverse-proxy
        ./modules/system
      ];
    };

    nixosConfigurations = {
      # homelab = nixpkgs.lib.nixosSystem {
      #   inherit system pkgs;
      #   specialArgs = {inherit inputs;};
      #   modules = [
      #     ./hosts/homelab/configuration.nix
      #     # ./hosts/homelab/hardward-configuration.nix
      #   ];
      # };

      homelab-test = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.default
          ./hosts/homelab-test/configuration.nix
        ];
      };
    };

    deploy.nodes = {
      homelab-test = {
        hostname = "10.0.42.3";
        profiles.system = {
          user = "root";
          sshUser = "dotboris";
          interactiveSudo = true;
          fastConnection = true;
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.homelab-test;
        };
      };
    };

    packages.${system} = {
      installer-iso = callPackage ./packages/installer-iso.nix {};
    };

    checks.${system} = let
      inherit (pkgs.lib.attrsets) nameValuePair mapAttrs';
      buildAll = {
        prefix,
        output,
        mapFn ? (x: x),
      }:
        mapAttrs' (name: value: nameValuePair "${prefix}${name}" (mapFn value)) output;
    in
      {
        statix = pkgs.runCommand "statix" {buildInputs = [pkgs.statix];} ''
          statix check -c ${./statix.toml} ${./.}
          touch $out
        '';
      }
      # Build all packages
      // buildAll {
        prefix = "build-pkg-";
        output = self.packages.${system};
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
}
