{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages = let
      version = "0.5.3";
      src = pkgs.fetchFromGitHub {
        owner = "dotboris";
        repo = "standard-backups";
        rev = "v${version}";
        sha256 = "sha256-PBb9MjQgxaQ7l3vyz/y3+WVc9JEFGkatoVIW2NGmB18=";
      };
      vendorHash = "sha256-ITSMgRp9OsFzpwGpYxnUGhuiQ0I9ClBe2x6qt/8FJYU=";
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
        passthru.updateScript = self.lib.updateScript {inherit pkgs pname;};
      };
      standard-backups-restic-backend = pkgs.buildGoModule rec {
        inherit src vendorHash version;
        pname = "standard-backups-restic-backend";
        subPackages = ["cmd/standard-backups-restic-backend"];
        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.restic
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
