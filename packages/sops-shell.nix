{...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.sops-shell = pkgs.writeShellApplication {
      name = "sops-shell";
      runtimeInputs = [
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
        pkgs.fish
        pkgs.jq
      ];
      text = ''
        if [ "$#" -lt 1 ]; then
          echo 'usage: sops-shell <host>'
          echo
          # shellcheck disable=SC2016
          echo 'Start a shell with the secrets of the given <host> exposed as the $secrets environment variable'
          exit 1
        fi

        host=$1

        echo "Entering shell. Secrets for $host are available as \$secrets"
        echo
        echo "Example usage:"
        # shellcheck disable=SC2016
        echo '$ echo "$secrets" | jq -r .some.secret.value'

        # shellcheck disable=SC2016
        sops exec-file \
          --output-type json \
          "hosts/$host/secrets.sops.yaml" \
          'secrets="$(cat {})" fish'
      '';
    };
    apps.sops-shell = {
      type = "app";
      program = self'.packages.sops-shell;
      meta.description = "Start shell with host secrets exposed as $secrets env var";
    };
  };
}
