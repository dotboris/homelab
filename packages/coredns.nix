{...}: {
  perSystem = {pkgs, ...}: {
    packages.coredns = pkgs.coredns.override {
      externalPlugins = [
        {
          name = "blocklist";
          repo = "github.com/relekang/coredns-blocklist";
          version = "v1.13.3";
          position.before = "forward";
        }
      ];
      vendorHash = "sha256-Q+cyZ1IPxyn90PCJGr+73vlSjuIy6B9pI1HZ4IMRQnc=";
    };
  };
}
