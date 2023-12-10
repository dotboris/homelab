{...}: {
  system.stateVersion = "23.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.dotboris = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # allow sudo
    ];
    initialPassword = "supersecret"; # TODO: don't store cleartext password
  };
}
