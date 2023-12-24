{...}: {
  system.stateVersion = "23.11";

  imports = [
    ../../modules/adblock
    ../../modules/home-page
    ../../modules/monitoring
    ../../modules/remote-access
    ../../modules/reverse-proxy
  ];

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
