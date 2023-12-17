{inputs, ...}: {
  imports = [
    inputs.nixos-generators.nixosModules.vm
    # inputs.nixos-generators.nixosModules.vm-nogui
  ];

  virtualisation.useBootLoader = true;
  # virtualisation.useEFIBoot = true;

  virtualisation.forwardPorts = [
    {
      from = "host";
      guest.port = 22;
      host.port = 10022;
    }
  ];
}
