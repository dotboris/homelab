{...}: {
  perSystem = {pkgs, ...}: {
    packages.coredns = pkgs.coredns.override {
      externalPlugins = [
        {
          name = "blocklist";
          repo = "github.com/relekang/coredns-blocklist";
          version = "v1.13.0";
          position.before = "forward";
        }
      ];
      vendorHash = "sha256-Drakfm+dzLmHlLHfl6O4tfOe1bRZRSYpTGkpkhXHY0w=";
    };
  };
}
