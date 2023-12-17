{
  lib,
  config,
  ...
}: {
  imports = [];

  boot.initrd.availableKernelModules = ["ata_piix" "xhci_pci" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [];

  networking = {
    useDHCP = true;
    hostName = lib.mkForce "homelab-test";
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
