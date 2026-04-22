{inputs, ...}: {
  flake.modules.nixos.default = {...}: {
    imports = [
      inputs.copyparty.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
