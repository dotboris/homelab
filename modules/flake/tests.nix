{
  self,
  lib,
  ...
}: {
  flake.modules.nixosTest = {}; # default to handle empty case
  perSystem = {pkgs, ...}: {
    checks =
      lib.mapAttrs'
      (name: testMod:
        lib.nameValuePair "test-${name}" (pkgs.testers.runNixOSTest {
          imports = [
            # Saves them from having to set the name
            {inherit name;}
            testMod
          ];
        }))
      self.modules.nixosTest;
  };
}
