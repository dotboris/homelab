{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
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
    nixpkgs-unstable,
    nixos-anywhere,
    sops-nix,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    pkgsUnstable = import nixpkgs-unstable {
      inherit system;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "netdata" # The UI is non OSS. It's under its own funny license.
        ];
      overlays = [
        # Use unstable coredns. It's supports ordering plugins correctly
        (prev: final: {
          inherit (pkgsUnstable) coredns;
        })
      ];
    };
    callPackage = path: overrides: pkgs.callPackage path {inherit inputs;} // overrides;
  in {
    formatter.${system} = pkgs.writeShellApplication {
      name = "alejandra-format-repo";
      runtimeInputs = [pkgs.alejandra];
      text = "alejandra .";
    };
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.nil
        pkgs.alejandra
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
      homelab = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.default
          ./hosts/homelab/configuration.nix
        ];
      };
      homelab-test = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.default
          ./hosts/homelab-test/configuration.nix
        ];
      };
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
    };

    packages.${system} = {
      anudeepnd-allowlist = callPackage ./packages/anudeepnd-allowlist.nix {};
      installer-iso = callPackage ./packages/installer-iso.nix {};
      stevenblack-blocklist = callPackage ./packages/stevenblack-blocklist.nix {};
      update-packages = callPackage ./packages/update-packages.nix {};
      coredns = callPackage ./packages/coredns.nix {};
    };

    apps.${system}.update-packages = {
      type = "app";
      program = "${self.packages.${system}.update-packages}/bin/update-packages";
    };

    checks.${system} = let
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
