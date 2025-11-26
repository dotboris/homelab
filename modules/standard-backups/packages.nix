{...}: {
  perSystem = {pkgs, ...}: {
    packages = let
      src = pkgs.fetchFromGitHub {
        owner = "dotboris";
        repo = "standard-backups";
        rev = "eded838085951c9f594da7476a04f29d06e9535f";
        sha256 = "sha256-MP+UMxN5JtK1O4tXRbJwrcVNGzu0/YeIriIjKNFpmfk=";
      };
      vendorHash = "sha256-XVnWFwDzX0MQT/MT8uB/eHzpJ4g9VYpBKSASw5L4PVM=";
      generateBackendManifest = pkgs.writeShellApplication {
        name = "generateBackendManifest";
        text = ''
          name=$1
          bin=$2
          manifest=$3
          mkdir -p "$(dirname "$manifest")"
          {
            echo "version: 1"
            echo "protocol-version: 1"
            echo "name: $name"
            echo "bin: $bin"
          } > "$manifest"
        '';
      };
    in {
      standard-backups = pkgs.buildGoModule rec {
        inherit src vendorHash;
        name = "standard-backups";
        subPackages = ["cmd/standard-backups"];
        meta.mainProgram = name;
      };
      standard-backups-restic-backend = pkgs.buildGoModule rec {
        inherit src vendorHash;
        name = "standard-backups-restic-backend";
        subPackages = ["cmd/standard-backups-restic-backend"];
        nativeBuildInputs = [
          pkgs.makeWrapper
          generateBackendManifest
        ];
        postInstall = ''
          generateBackendManifest restic \
            $out/bin/standard-backups-restic-backend \
            $out/share/standard-backups/backends/restic.yaml
          wrapProgram $out/bin/standard-backups-restic-backend \
            --prefix PATH : ${pkgs.restic}/bin
        '';
        meta.mainProgram = name;
      };
      standard-backups-rsync-backend = pkgs.buildGoModule rec {
        inherit src vendorHash;
        name = "standard-backups-rsync-backend";
        subPackages = ["cmd/standard-backups-rsync-backend"];
        nativeBuildInputs = [
          pkgs.makeWrapper
          generateBackendManifest
        ];
        postInstall = ''
          generateBackendManifest rsync \
            $out/bin/standard-backups-rsync-backend \
            $out/share/standard-backups/backends/rsync.yaml
          wrapProgram $out/bin/standard-backups-rsync-backend \
            --prefix PATH : ${pkgs.rsync}/bin
        '';
        meta.mainProgram = name;
      };
    };
  };
}
