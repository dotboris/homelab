{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-images = {
      url = "github:nix-community/nixos-images";
      inputs.nixos-unstable.follows = "nixpkgs";
      inputs.nixos-2311.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-generators,
    nixos-images,
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

      # VM meant to test changes to the real homelab
      homelab-test = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/homelab/configuration.nix
          ./hosts/vm/configuration.nix
          ./hosts/vm/hardward-configuration.nix
        ];
      };
    };

    packages.${system} = {
      # Build & Run the test VM
      run-vm = let
        vm = self.nixosConfigurations.homelab-test;
      in
        vm.config.system.build.vm;
      installer-iso = nixos-images.packages.${system}.image-installer-nixos-unstable;
    };

    apps.${system} = {
      # Starts the homelab-test VM in QEMU
      vm = {
        type = "app";
        program = "${callPackage ./scripts/start-vm.nix {}}";
      };

      # Connects to the homelab-test VM through SSH
      # This requires the right private key on your system to work
      ssh-vm = {
        type = "app";
        program = "${callPackage ./scripts/ssh-vm.nix {}}";
      };
    };
  };
}
