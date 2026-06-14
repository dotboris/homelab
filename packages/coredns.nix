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
      vendorHash = "sha256-EmJfVVjMG4UIJITe6sGxi8aBMbAc9xiyWyIKyOh3ORI=";
    };
  };
}
