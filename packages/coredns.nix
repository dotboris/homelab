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
      vendorHash = "sha256-hCb6FlCPBece/QVTPObJC5JOwXsaUmpZ3idsK4QeTw0=";
    };
  };
}
