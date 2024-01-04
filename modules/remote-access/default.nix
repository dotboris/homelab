{config, pkgs, ...}: {
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

  sops.secrets."users/dotboris".neededForUsers = true;

  users.users.dotboris = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # allow sudo
    ];
    hashedPasswordFile = config.sops.secrets."users/dotboris".path;

    shell = pkgs.fish;

    openssh.authorizedKeys.keys = [
      # dotboris@desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOrL2lDUwOQ9K98de3YQqscdLAHqoZJCuCocL6TZYZq"
    ];
  };

  programs.fish.enable = true; # shell for dotboris
}
