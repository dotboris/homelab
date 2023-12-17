{pkgs, ...}: {
  services.openssh = {
    enable = true;
    allowSFTP = false;
    settings = {
      # Auth hardening
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";

      X11Forwarding = false;
    };
  };

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

  programs.fish.enable = true; # shell for dotboris
}
