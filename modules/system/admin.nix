{
  config,
  pkgs,
  ...
}: let
  consts = import ../../consts.nix;
in {
  services.openssh = {
    enable = true;
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
    openssh.authorizedKeys.keys = consts.dotboris.ssh.pubKeys;
  };
  programs.fish.enable = true; # shell for dotboris
}
