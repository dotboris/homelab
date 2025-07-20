{pkgs, ...}:
pkgs.coredns.override {
  externalPlugins = [
    {
      name = "blocklist";
      repo = "github.com/relekang/coredns-blocklist";
      version = "v1.13.0";
      position.before = "forward";
    }
  ];
  vendorHash = "sha256-0GaAaCOrXn2WXkqGltOntZ+W6M1NouWs9ymic8Ajs8k=";
}
