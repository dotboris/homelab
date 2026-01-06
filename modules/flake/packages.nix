{lib, ...}: {
  flake.lib.updateScript = {
    pkgs,
    pname,
    extraArgs ? [],
  }:
    pkgs.writeShellApplication {
      name = "update-${pname}";
      text = ''
        ${lib.getExe pkgs.nix-update} \
          --flake ${lib.escapeShellArg pname} \
          ${lib.escapeShellArgs extraArgs}
      '';
    };

  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    packages.update-packages = let
      packages = lib.pipe self'.packages [
        (lib.filterAttrs (_: p: builtins.hasAttr "updateScript" p))
        (lib.mapAttrs (_: p: p.updateScript))
      ];
    in
      pkgs.writeShellApplication {
        name = "update-packages";
        text =
          ''
            all_ok=1
          ''
          + (lib.pipe packages [
            (lib.mapAttrsToList (name: script: ''
              echo ">>> Updating ${lib.escapeShellArg name}"
              if ! ${lib.getExe script}; then
                all_ok=0
              fi
            ''))
            (lib.concatStringsSep "\n")
          ])
          + ''
            if [ $all_ok -eq 0 ]; then
              exit 1
            fi
          '';
      };
    apps.update-packages = {
      type = "app";
      program = "${self'.packages.update-packages}/bin/update-packages";
      meta.description = "Update all packages in this flake with passthru.updateScript = ...";
    };

    checks = lib.mapAttrs' (name: package:
      lib.nameValuePair "package-${name}" package)
    self'.packages;
  };
}
