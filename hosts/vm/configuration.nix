{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-generators.nixosModules.vm
    # inputs.nixos-generators.nixosModules.vm-nogui
  ];

  virtualisation.useBootLoader = true;
  virtualisation.useEFIBoot = true;

  boot.loader = {
    # EFI Boot
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    # Use systemd boot
    grub.enable = false;
    systemd-boot.enable = true;

    # Skip the menu
    timeout = 0;
  };

  virtualisation.forwardPorts = [
    {
      from = "host";
      guest.port = 22;
      host.port = 10022;
    }
  ];
}
