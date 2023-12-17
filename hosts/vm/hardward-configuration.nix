{
  lib,
  config,
  ...
}: {
  imports = [];

  # When Nix builds a VM, it uses well-defined labels, we reuse those. 
  # See: https://github.com/NixOS/nixpkgs/blob/4c501306af1ab6c19491fdafebb30fd097eb42c5/nixos/modules/virtualisation/qemu-vm.nix#L264-L267
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
    };
  };

  swapDevices = [];

  networking = {
    useDHCP = true;
    hostName = lib.mkForce "homelab-test";
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
