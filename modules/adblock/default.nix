{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.self.packages.${pkgs.system}) anudeepnd-allowlist stevenblack-blocklist;
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
          "${stevenblack-blocklist}/hosts"
        ];
        whiteLists.ads = [
          "${anudeepnd-allowlist}/domains/whitelist.txt"
        ];

        clientGroupsBlock.default = ["ads"];
      };

      # TODO: manage this dynamically with information from elsewhere
      customDNS.mapping = let
        homelab = "10.0.42.2";
        homelab-test = "10.0.42.3";
      in {
        "homelab.lan" = homelab;
        "home.dotboris.io" = homelab;
        "archive.dotboris.io" = homelab;
        "feeds.dotboris.io" = homelab;
        "netdata.dotboris.io" = homelab;
        "traefik.dotboris.io" = homelab;
        "ntfy.dotboris.io" = homelab;
        "homelab-test.lan" = homelab-test;
        "home-test.dotboris.io" = homelab-test;
        "archive-test.dotboris.io" = homelab-test;
        "feeds-test.dotboris.io" = homelab-test;
        "netdata-test.dotboris.io" = homelab-test;
        "traefik-test.dotboris.io" = homelab-test;
        "ntfy-test.dotboris.io" = homelab-test;
      };
    };
  };

  services.resolved.enable = false;
  networking.nameservers = ["127.0.0.1:${dnsPort}"];
  networking.firewall.allowedUDPPorts = [dnsPort];
}
