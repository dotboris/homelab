{self, ...}: {
  flake.modules.nixosTest.gen-secrets = {pkgs, ...}: {
    containers.machine = {
      imports = [self.modules.nixos.gen-secrets];
      config = {
        services.gen-secrets.secrets.default = {};

        users.users.test = {
          isSystemUser = true;
          group = "test";
        };
        users.groups.test = {};
        users.groups.other = {};
        services.gen-secrets.secrets.customized = {
          owner = "test";
          group = "other";
          mode = "440";
          size = 42;
        };
      };
    };
    testScript =
      # python
      ''
        def print_unit_logs(unit):
            logs = machine.succeed(f"journalctl --no-pager -u {unit}")
            print(logs)

        SECRETS_DIR = "/var/lib/gen-secrets/secrets"

        start_all()
        machine.wait_for_unit("default.target")

        machine.start_job("gen-secrets-default.service")
        machine.wait_for_file(f"{SECRETS_DIR}/default", 10)

        dir_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}")
        t.assertEqual(dir_stat, "755 root root")

        with subtest("default secret"):
            default_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}/default")
            t.assertEqual(default_stat, "400 root root")

            _, default_value = machine.execute(f"cat {SECRETS_DIR}/default")
            t.assertEqual(len(default_value), 64)

            machine.start_job("gen-secrets-default.service")
            machine.wait_until_succeeds("systemctl --no-pager list-jobs --full | grep 'No jobs'")
            machine.wait_until_succeeds("systemctl --no-pager show gen-secrets-default.service --property ActiveState | grep ActiveState=inactive")
            machine.wait_until_succeeds("journalctl --no-pager -I -u gen-secrets-default.service | grep 'Secret default already exists'")

            default_value_again = machine.succeed(f"cat {SECRETS_DIR}/default")
            t.assertEqual(default_value, default_value_again)

            print_unit_logs("gen-secrets-default.service")

        with subtest("customized secret"):
            machine.start_job("gen-secrets-customized.service")
            machine.wait_for_file(f"{SECRETS_DIR}/customized", 10)

            default_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}/customized")
            t.assertEqual(default_stat, "440 test other")

            _, default_value = machine.execute(f"cat {SECRETS_DIR}/customized")
            t.assertEqual(len(default_value), 42)

            print_unit_logs("gen-secrets-customized.service")

        with subtest("fixes permissions"):
            machine.succeed(f"chown nobody:nogroup {SECRETS_DIR}/default")
            machine.succeed(f"chmod 777 {SECRETS_DIR}/default")
            default_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}/default")
            t.assertEqual(default_stat, "777 nobody nogroup")

            machine.start_job("gen-secrets-default.service")
            machine.wait_for_file(f"{SECRETS_DIR}/default", 10)

            default_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}/default")
            t.assertEqual(default_stat, "400 root root")

            print_unit_logs("gen-secrets-default.service")
      '';
  };
}
