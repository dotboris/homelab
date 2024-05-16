{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixos-images = {
      url = "github:nix-community/nixos-images";
      inputs.nixos-unstable.follows = "nixpkgs";
      inputs.nixos-2311.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixos-stable.follows = "nixpkgs";
      inputs.nixos-images.follows = "nixos-images";
      inputs.disko.follows = "disko";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-anywhere,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    callPackage = path: overrides: pkgs.callPackage path {inherit inputs;} // overrides;
  in {
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        # Secrets management
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
        nixos-anywhere.packages.${system}.default
      ];
    };

    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/homelab/configuration.nix
          ./hosts/homelab/hardward-configuration.nix
        ];
      };

      homelab-test = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/homelab/configuration.nix
          ./hosts/homelab-test/configuration.nix
          ./hosts/homelab-test/hardward-configuration.nix
        ];
      };
    };

    packages.${system} = {
      installer-iso = callPackage ./packages/installer-iso.nix {};
    };
  };
}
