{...}: {
  system.stateVersion = "23.11";

  imports = [
    ../../modules/remote-access
  ];

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
