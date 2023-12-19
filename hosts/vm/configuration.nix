{inputs, ...}: {
  imports = [
    inputs.nixos-generators.nixosModules.vm
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
      host.port = 2022;
    }
    {
      from = "host";
      guest.port = 80;
      host.port = 8000;
    }
    {
      from = "host";
      guest.port = 443;
      host.port = 8443;
    }
  ];
}
