{lib, ...}: {
  perSystem = {pkgs, ...}: {
    packages = let
      src = pkgs.fetchFromGitHub {
        owner = "dotboris";
        repo = "standard-backups";
        rev = "253f26158289d5a3e4b3005ff26fc17264f86488";
        sha256 = "sha256-0cPRU8D69b4JNB85Qx4GUltQYY1CTgixuegJPs2Ik9A=";
      };
      vendorHash = "sha256-XVnWFwDzX0MQT/MT8uB/eHzpJ4g9VYpBKSASw5L4PVM=";
      generateBackendManifest = name: bin: ''
        manifestDir="$out/share/standard-backups/backends"
        manifest="$manifestDir/${lib.escapeShellArg name}.yaml"
        mkdir -p "$manifestDir"
        echo "version: 1" >> "$manifest"
        echo "protocol-version: 1" >> "$manifest"
        echo "name: ${lib.escapeShellArg name}" >> "$manifest"
        echo "bin: $out/bin/${lib.escapeShellArg bin}" >> "$manifest"
      '';
    in {
      standard-backups = pkgs.buildGoModule {
        inherit src vendorHash;
        name = "standard-backups";
        subPackages = ["cmd/standard-backups"];
      };
      standard-backups-restic-backend = pkgs.buildGoModule {
        inherit src vendorHash;
        name = "standard-backups-restic-backend";
        subPackages = ["cmd/standard-backups-restic-backend"];
        postInstall = generateBackendManifest "restic" "standard-backups-restic-backend";
        propagatedBuildInputs = [pkgs.restic];
      };
      standard-backups-rsync-backend = pkgs.buildGoModule {
        inherit src vendorHash;
        name = "standard-backups-rsync-backend";
        subPackages = ["cmd/standard-backups-rsync-backend"];
        postInstall = generateBackendManifest "rsync" "standard-backups-rsync-backend";
        propagatedBuildInputs = [pkgs.rsync];
      };
    };
  };
}
