{...}: {
  perSystem = {pkgs, ...}: {
    packages.standard-backups = pkgs.buildGoModule {
      name = "standard-backups";
      src = pkgs.fetchFromGitHub {
        owner = "dotboris";
        repo = "standard-backups";
        rev = "253f26158289d5a3e4b3005ff26fc17264f86488";
        sha256 = "sha256-0cPRU8D69b4JNB85Qx4GUltQYY1CTgixuegJPs2Ik9A=";
      };
      vendorHash = "sha256-XVnWFwDzX0MQT/MT8uB/eHzpJ4g9VYpBKSASw5L4PVM=";
      passthru.update = true;
      subPackages = [
        "cmd/standard-backups"
        "cmd/standard-backups-restic-backend"
        "cmd/standard-backups-rsync-backend"
      ];
    };
  };
}
