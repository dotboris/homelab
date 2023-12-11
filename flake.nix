{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
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

    packages.${system}.vm = self.nixosConfigurations.homelab.config.system.build.vm;
    apps.${system}.vm = {
      type = "app";
      program = "${self.packages.${system}.vm}/bin/run-homelab-vm";
    };

    nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # nixos-generators.nixosModules.vagrant-virtualbox
        ./configuration.nix
        ./modules/openssh.nix
      ];
    };
  };
}
