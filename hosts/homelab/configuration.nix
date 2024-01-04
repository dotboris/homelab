{inputs, ...}: {
  system.stateVersion = "23.11";

  imports = [
    inputs.sops-nix.nixosModules.sops

    ../../modules/adblock
    ../../modules/feeds
    ../../modules/home-page
    ../../modules/monitoring
    ../../modules/remote-access
    ../../modules/reverse-proxy
  ];

  homelab = {
    homepage = {
      port = 8001;
      host = "home.dotboris.io";
    };

    reverseProxy.traefikDashboardHost = "traefik.dotboris.io";

    monitoring = {
      netdata = {
        port = 8002;
        host = "netdata.dotboris.io";
      };
      traefik.exporterPort = 8003;
    };

    feeds = {
      httpPort = 8004;
      host = "feeds.dotboris.io";
    };
  };

  sops = {
    # TODO: real secret

    # Generate an age key based on our SSH host key.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    gnupg.sshKeyPaths = []; # Turn off GPG key gen
  };

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
