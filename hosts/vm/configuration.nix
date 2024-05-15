{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  homelab.reverseProxy.tls.snakeOil.enable = true;

  boot.loader = {
    grub.enable = true;
    timeout = 0; # Skip the menu
  };

  sops = {
    defaultSopsFile = lib.mkForce ../../secrets/vm.sops.yaml;

    # Generate an age key based on our SSH host key.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    gnupg.sshKeyPaths = []; # Turn off GPG key gen
  };
}
