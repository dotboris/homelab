{inputs, ...}: {
  flake.modules.nixos.default = {...}: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
