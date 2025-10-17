{...}: {
  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    apps.update-packages = let
      packagesToUpdate = lib.filterAttrs (_: p: p.update or false) self'.packages;
      packageNamesToUpdate = builtins.attrNames packagesToUpdate;
      package = pkgs.writeShellApplication {
        name = "update-packages";
        runtimeInputs = [pkgs.nix-update];
        text = ''
          all_ok=1
          packages=(${lib.escapeShellArgs packageNamesToUpdate})
          for package in "''${packages[@]}"; do
            echo ">>> Updating $package"
            if ! nix-update --flake "$package"; then
              all_ok=0
            fi
          done

          if [ $all_ok -eq 0 ]; then
            exit 1
          fi
        '';
      };
    in {
      type = "app";
      program = "${package}/bin/update-packages";
      meta.description = "Update all packages in this flake with passthru.update = true";
    };
  };
}
