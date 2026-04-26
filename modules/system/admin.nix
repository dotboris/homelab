{self, ...}: {
  flake.modules.nixos.default = {
    config,
    pkgs,
    ...
  }: {
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
      openssh.authorizedKeys.keys = self.lib.sshKeys.dotboris;
    };
    programs.fish.enable = true; # shell for dotboris
  };
}
