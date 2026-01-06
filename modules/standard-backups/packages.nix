{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages = let
      src = pkgs.fetchFromGitHub {
        owner = "dotboris";
        repo = "standard-backups";
        rev = "0b6703515cc2b6478ef4cbc3766b05ae86f178c3";
        sha256 = "sha256-XS5Sw6n/Gg3z3Yddi6+JEtUL3FFs0fvOKe7IF+bo+Uw=";
      };
      vendorHash = "sha256-5d5r+uIVrhYrh+wNd44Tdzzn8uqhW3vwL6HKF0PdWkk=";
      version = "${builtins.substring 0 7 src.rev}";
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
        inherit src vendorHash version;
        pname = "standard-backups";
        subPackages = ["cmd/standard-backups"];
        meta.mainProgram = pname;
        passthru.updateScript = self.lib.updateScript {
          inherit pkgs pname;
          extraArgs = ["--version=branch=main"];
        };
      };
      standard-backups-restic-backend = pkgs.buildGoModule rec {
        inherit src vendorHash version;
        pname = "standard-backups-restic-backend";
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
        meta.mainProgram = pname;
      };
      standard-backups-rsync-backend = pkgs.buildGoModule rec {
        inherit src vendorHash version;
        pname = "standard-backups-rsync-backend";
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
        meta.mainProgram = pname;
      };
    };
  };
}
