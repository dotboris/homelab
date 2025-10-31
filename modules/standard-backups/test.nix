{
  self,
  moduleWithSystem,
  ...
}: {
  flake.modules.nixosTest.standard-backups = moduleWithSystem ({self', ...}: {pkgs, ...}: {
    nodes.machine = {
      imports = [self.modules.nixos.standard-backups];
      services.standard-backups = {
        enable = true;
        extraPackages = [
          self'.packages.standard-backups-restic-backend
          self'.packages.standard-backups-rsync-backend
          (pkgs.writeTextDir "share/standard-backups/recipes/test.yaml" ''
            version: 1
            name: test
            paths: [/var/lib/back-me-up/]
          '')
        ];
        settings = {
          secrets.bogus.literal = "supersecret";
          destinations.restic-test = {
            backend = "restic";
            options = {
              repo = "/var/lib/backups/restic-test";
              env.RESTIC_PASSWORD = "{{ .Secrets.bogus }}";
            };
          };
          destinations.rsync-test = {
            backend = "rsync";
            options.destination-dir = "/var/lib/backups/rsync-test";
          };
          jobs.test = {
            recipe = "test";
            backup-to = ["restic-test" "rsync-test"];
          };
        };
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/backups/ 0700 root root"
        "d /var/lib/back-me-up/ 0700 root root"
        "d /var/lib/restore/ 0700 root root"
      ];
    };
    testScript = {...}: ''
      start_all()
      machine.succeed("standard-backups print-config")
      machine.succeed("standard-backups validate-config")

      with subtest("cli"):
        machine.succeed("echo hello from cli > /var/lib/back-me-up/file.txt")
        machine.succeed("standard-backups backup test")

        # restore restic
        machine.succeed("""
          standard-backups exec -d restic-test -- \
            restore latest:/var/lib/back-me-up/ \
            -t /var/lib/restore/restic-cli/
        """)
        assert "hello from cli" in machine.succeed("cat /var/lib/restore/restic-cli/file.txt")

        # check rsync
        assert "hello from cli" in machine.succeed("""
          file="$(find /var/lib/backups/rsync-test -name file.txt | sort | tail -n1)"
          cat "$file"
        """)

      with subtest("service"):
        machine.succeed("echo hello from service > /var/lib/back-me-up/file.txt")
        machine.start_job("standard-backups@test")

        # restore rsync
        machine.succeed("""
          standard-backups exec -d restic-test -- \
            restore latest:/var/lib/back-me-up/ \
            -t /var/lib/restore/restic-service/
        """)
        assert "hello from service" in machine.succeed("cat /var/lib/restore/restic-service/file.txt")

        # check rsync
        assert "hello from service" in machine.succeed("""
          file="$(find /var/lib/backups/rsync-test -name file.txt | sort | tail -n1)"
          cat "$file"
        """)
    '';
  });
}
