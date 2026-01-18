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
      vendorHash = "sha256-p/Rr+EFGjx0a7j/3I75jy5VLkz2n9ck1QuYkBV1V57M=";
    };
  };
}
