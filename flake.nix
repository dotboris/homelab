{
  description = "Home Lab / Home Server";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-23.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in rec {
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default =
      pkgs.mkShell {
        packages = [];
      };

    apps.${system}.vm = {
      type = "app";
      program = "${packages.${system}.vm}/bin/run-nixos-vm";
    };
    packages.${system}.vm = nixosConfigurations.homelab.config.system.build.vm;
    
    nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
      ];
    };
  };
}
