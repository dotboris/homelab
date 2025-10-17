{lib, ...}: {
  perSystem = {self', ...}: {
    checks = lib.mapAttrs' (name: package:
      lib.nameValuePair "package-${name}" package)
    self'.packages;
  };
}
