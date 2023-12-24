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

    # Build & Run the test VM
    packages.${system} = {
      run-vm = let
        vm = self.nixosConfigurations.homelab-test;
      in
        vm.config.system.build.vm;
    };

    apps.${system} = {
      # Starts the homelab-test VM in QEMU
      vm = {
        type = "app";
        program = let
          runVm = self.packages.${system}.run-vm;
          script = pkgs.writeShellScript "start-vm" ''
            set -x
            rm ./homelab-test-efi-vars.fd
            rm ./homelab-test.qcow2
            exec ${runVm}/bin/run-homelab-test-vm
          '';
        in "${script}";
      };

      # Connects to the homelab-test VM through SSH
      # This requires the right private key on your system to work
      ssh-vm = {
        type = "app";
        program = let
          script =
            pkgs.writeShellScript "ssh-vm"
            ''
              ${pkgs.openssh}/bin/ssh \
                -o "UserKnownHostsFile=/dev/null" \
                -o "StrictHostKeyChecking=no" \
                -p 2022 \
                dotboris@localhost
            '';
        in "${script}";
      };
    };
  };
}
