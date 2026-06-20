{...}: {
  flake.modules.nixos.default = {...}: {
    homelab.backups = {
      defaultRetentionProfile = "medium";
      retentionProfiles = {
        long = {
          last = 4; # Assuming 4 backups a day, that keeps them all
          daily = 7;
          weekly = 4;
          monthly = 12;
          yearly = 7;
        };
        medium = {
          last = 4; # Assuming 4 backups a day, that keeps them all
          daily = 7;
          weekly = 4;
          monthly = 12;
          yearly = 1;
        };
        short = {
          last = 4; # Assuming 4 backups a day, that keeps them all
          daily = 7;
          weekly = 4;
          monthly = 1;
        };
      };
      jobs = {
        freshrss.retentionProfile = "short";
        paperless.retentionProfile = "long";
        music.retentionProfile = "short";
      };
    };
  };
}
