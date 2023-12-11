{pkgs, ...}: {
  system.stateVersion = "23.11";

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  users.users.dotboris = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # allow sudo
    ];
    initialPassword = "supersecret"; # TODO: don't store cleartext password

    shell = pkgs.fish;

    openssh.authorizedKeys.keys = [
      # dotboris@desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOrL2lDUwOQ9K98de3YQqscdLAHqoZJCuCocL6TZYZq"
    ];
  };

  programs.fish.enable = true;

  networking = {
    hostName = "homelab";
    useDHCP = true; # TODO: probably a bad idea for prod
  };
}
