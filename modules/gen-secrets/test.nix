{self, ...}: {
  flake.modules.nixosTest.gen-secrets = {pkgs, ...}: {
    containers.machine = {
      imports = [self.modules.nixos.gen-secrets];
      config = {
        services.gen-secrets.secrets.default = {};
      };
    };
    testScript = ''
      SECRETS_DIR = "/var/lib/gen-secrets/secrets"

      start_all()
      machine.wait_for_unit("default.target")

      machine.start_job("gen-secrets-default.service")
      machine.wait_for_file(f"{SECRETS_DIR}/default", 10)

      dir_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}")
      t.assertEqual(dir_stat, "755 root root")

      default_stat = machine.succeed(f"stat --printf '%a %U %G' {SECRETS_DIR}/default")
      t.assertEqual(default_stat, "400 root root")

      _, default_value = machine.execute(f"cat {SECRETS_DIR}/default")
      t.assertNotEqual(default_value.strip(), "")

      machine.start_job("gen-secrets-default.service")
      machine.wait_until_succeeds("systemctl --no-pager list-jobs --full | grep 'No jobs'")
      machine.wait_until_succeeds("systemctl --no-pager show gen-secrets-default.service --property ActiveState | grep ActiveState=inactive")
      machine.wait_until_succeeds("journalctl --no-pager -I -u gen-secrets-default.service | grep 'Secret default already exists'")

      default_value_again = machine.succeed(f"cat {SECRETS_DIR}/default")
      t.assertEqual(default_value, default_value_again)

      logs = machine.succeed("journalctl --no-pager -u gen-secrets-default.service")
      print(logs)
    '';
  };
}
