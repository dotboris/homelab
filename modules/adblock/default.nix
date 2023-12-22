{pkgs, ...}: let
  dnsPort = 53;
in {
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = dnsPort;

      upstreams.groups.default = [
        # CloudFlare
        "https://one.one.one.one/dns-query"

        # UncensoredDNS
        "https://anycast.uncensoreddns.org/dns-query"

        # Quad9 base DNS server
        "https://dns.quad9.net/dns-query"
      ];

      # Resolving upstream DNS servers & blocklists
      bootstrapDns = [
        {
          upstream = "https://dns.quad9.net/dns-query";
          ips = [
            "9.9.9.9"
            "149.112.112.112"
          ];
        }
      ];

      blocking = let
        stevenblackBlocklist = let
          version = "3.14.40";
        in
          pkgs.fetchFromGitHub {
            name = "stevenback-blocklist-${version}";
            owner = "StevenBlack";
            repo = "hosts";
            rev = version;
            sha256 = "sha256-hTFIG1a/PNgDo5U57VmXDJvR3VWd8TKVinnLfJRlQGo=";
          };
        anudeepndAllowlist = let
          version = "2.0.1";
        in
          pkgs.fetchFromGitHub {
            name = "anudeepnd-allowlist-${version}";
            owner = "anudeepND";
            repo = "whitelist";
            rev = "v${version}";
            sha256 = "sha256-TWtYNxMU5gpe5Y4Th6tQaiOA09DBV7iJFPr9P7CAfag=";
          };
      in {
        blackLists.ads = [
          "${stevenblackBlocklist}/hosts"
        ];
        whiteLists.ads = [
          "${anudeepndAllowlist}/domains/whitelist.txt"
        ];

        clientGroupsBlock.default = ["ads"];
      };
    };
  };

  networking.firewall.allowedUDPPorts = [dnsPort];
}
