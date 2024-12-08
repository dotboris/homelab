{pkgs, ...}:
pkgs.coredns.override {
  externalPlugins = [
    {
      name = "blocklist";
      repo = "github.com/relekang/coredns-blocklist";
      version = "v1.12.0";
      position.before = "forward";
    }
  ];
  vendorHash = "sha256-ZuOq/hBozpXAWWmNvXg3scufJpLayQVuP44Q0K7+MWA=";
}
