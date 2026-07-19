{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.mail;
  in {
    options.homelab.mail = {
      enable = lib.mkEnableOption "Outbound mail";
      mailgunHost = lib.mkOption {
        type = lib.types.str;
        default = "smtp.mailgun.org";
      };
    };
    config = lib.mkIf cfg.enable {
      sops = {
        secrets = {
          "mail/mailgun/username" = {};
          "mail/mailgun/password" = {};
        };
        templates = let
          ph = config.sops.placeholder;
        in {
          opensmtpd-secrets-table = {
            owner = "smtpd";
            content = ''
              mailgun: ${ph."mail/mailgun/username"}:${ph."mail/mailgun/password"}
            '';
          };
        };
      };
      services.opensmtpd = {
        enable = true;
        setSendmail = true;
        serverConfiguration = ''
          table secrets file:${config.sops.templates.opensmtpd-secrets-table.path}

          listen on lo

          action "relay_mailgun" \
            relay \
            tls \
            host smtp+tls://mailgun@${cfg.mailgunHost}:587 \
            auth <secrets>

          match \
            from local \
            for any \
            action "relay_mailgun"

          match from any reject
        '';
      };
    };
  };
}
