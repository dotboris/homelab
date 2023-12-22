{...}: let
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

      blocking = {
        blackLists.ads = [
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        ];
        whiteLists.ads = [
          "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt"
        ];

        clientGroupsBlock.default = ["ads"];
      };
    };
  };

  networking.firewall.allowedUDPPorts = [dnsPort];
}
