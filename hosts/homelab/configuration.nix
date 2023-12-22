{...}: {
  system.stateVersion = "23.11";

  imports = [
    ../../modules/remote-access
    ../../modules/reverse-proxy

    ../../modules/home-page
    ../../modules/adblock
  ];

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
