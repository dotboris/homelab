{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-generators,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default = pkgs.mkShell {
      packages = [];
    };

    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/homelab/configuration.nix
          ./hosts/homelab/hardward-configuration.nix
        ];
      };

      homelab-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/homelab/configuration.nix
          ./hosts/vm/configuration.nix
          ./hosts/vm/hardward-configuration.nix
        ];
      };
    };

    # Build & Run the test VM
    packages.${system}.vm = self.nixosConfigurations.homelab-vm.config.system.build.vm;
    apps.${system} = {
      vm = {
        type = "app";
        program = "${self.packages.${system}.vm}/bin/run-homelab-test-vm";
      };
      ssh-vm = {
        type = "app";
        program = let
          script =
            pkgs.writeShellScript "ssh-vm"
            ''
              ${pkgs.openssh}/bin/ssh \
                -o "UserKnownHostsFile=/dev/null" \
                -o "StrictHostKeyChecking=no" \
                -p 10022 \
                dotboris@localhost
            '';
        in "${script}";
      };
    };
  };
}
