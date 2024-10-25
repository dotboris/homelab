{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
with lib; let
  packages = inputs.self.packages.${system};
  packagesToUpdate = filterAttrs (_: p: p.update or false) packages;
  packageNamesToUpdate = builtins.attrNames packagesToUpdate;
in
  pkgs.writeShellApplication {
    name = "update-packages";
    runtimeInputs = [pkgs.nix-update];
    text = ''
      all_ok=1
      packages=(${escapeShellArgs packageNamesToUpdate})
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
  }
