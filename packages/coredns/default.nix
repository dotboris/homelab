{pkgs, ...}:
pkgs.coredns.override {
  externalPlugins = [
    {
      name = "blocklist";
      repo = "github.com/relekang/coredns-blocklist";
      version = "v1.12.0";
    }
  ];
  vendorHash = "sha256-MuGsozHqZ0AdrRFxXFIZe9p2YVdFJlBnQyu8rUFtgiQ=";
}
