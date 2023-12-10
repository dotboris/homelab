{...}: {
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
}
