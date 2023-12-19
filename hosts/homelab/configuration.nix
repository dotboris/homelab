{...}: {
  system.stateVersion = "23.11";

  imports = [
    ../../modules/remote-access
    ../../modules/reverse-proxy

    ../../modules/home-page
  ];

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
