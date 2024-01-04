{
  inputs,
  lib,
  ...
}: {
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

  sops = {
    defaultSopsFile = lib.mkForce ../../secrets/vm.sops.yaml;

    # Instead of generating an age key from the SSH host key, we just specify
    # the age key directly. This key is hard-coded in the repo and used for
    # testing. It's obviously not secure at all since it's public but the
    # secreds it protects are all bogus.
    age.sshKeyPaths = lib.mkForce [];
    age.keyFile = lib.mkForce ../../secrets/dummy-vm.age.txt;
  };

  virtualisation.forwardPorts = [
    {
      from = "host";
      guest.port = 22;
      host.port = 2022;
    }
    {
      from = "host";
      proto = "udp";
      guest.port = 53;
      host.port = 5053;
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
