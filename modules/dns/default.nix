{
  self,
  moduleWithSystem,
  ...
}: {
  flake.modules.nixos.dns = moduleWithSystem ({self', ...}: {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      concatStringsSep
      mkIf
      mkEnableOption
      mkOption
      types
      ;
    inherit
      (self'.packages)
      coredns
      anudeepnd-allowlist
      stevenblack-blocklist
      ;
    cfg = config.homelab.dns;
    yaml = pkgs.formats.yaml {};
    hosts = {
      homelab = {
        name = "homelab.lan";
        aliases = [
          "home.dotboris.io."
          "archive.dotboris.io."
          "cloud.dotboris.io."
          "feeds.dotboris.io."
          "netdata.dotboris.io."
          "search.dotboris.io."
          "traefik.dotboris.io."
          "ntfy.dotboris.io."
        ];
        ips = {
          lan = "10.0.42.2";
          tailscale = "100.69.230.33";
        };
      };
      homelab-test = {
        name = "homelab-test.lan";
        aliases = [
          "home-test.dotboris.io."
          "archive-test.dotboris.io."
          "cloud-test.dotboris.io."
          "feeds-test.dotboris.io."
          "netdata-test.dotboris.io."
          "search-test.dotboris.io."
          "traefik-test.dotboris.io."
          "ntfy-test.dotboris.io."
        ];
        ips = {
          lan = "10.0.42.3";
          tailscale = "100.67.226.105";
        };
      };
      homelab-test-foxtrot = {
        name = "homelab-test-foxtrot.lan";
        aliases = [
          "home-test-foxtrot.dotboris.io."
          "archive-test-foxtrot.dotboris.io."
          "cloud-test-foxtrot.dotboris.io."
          "feeds-test-foxtrot.dotboris.io."
          "netdata-test-foxtrot.dotboris.io."
          "search-test-foxtrot.dotboris.io."
          "traefik-test-foxtrot.dotboris.io."
          "ntfy-test-foxtrot.dotboris.io."
        ];
        ips = {
          lan = "192.168.122.3";
          tailscale = "100.103.210.109";
        };
      };
    };
  in {
    options.homelab.dns = {
      enable = mkEnableOption "dns server";
      port = mkOption {
        type = types.port;
        default = 53;
      };
      lanCidr = mkOption {
        type = types.str;
        description = "CIDR for the local network";
        default = "10.0.42.0/24";
      };
      tailscaleCidr = mkOption {
        type = types.str;
        description = "CIDR for the tailscale network";
        default = "100.0.0.0/8";
      };
    };

    config = mkIf cfg.enable {
      services = {
        coredns = {
          enable = true;
          extraArgs = ["-dns.port=${toString cfg.port}"];
          package = coredns;
          config = let
            hostLine = host: variant: (
              concatStringsSep " " ([host.ips.${variant} host.name] ++ host.aliases)
            );
          in ''
            (adblock) {
              blocklist ${stevenblack-blocklist}/blocklist.txt {
                allowlist ${anudeepnd-allowlist}/domains/whitelist.txt
              }
            }

            (forward) {
              forward . 127.0.0.1:5301 127.0.0.1:5302 127.0.0.1:5303
            }

            (common) {
              errors
              prometheus
            }

            . {
              view lan {
                expr incidr(client_ip(), '127.0.0.0/24') || incidr(client_ip(), '${cfg.lanCidr}')
              }
              hosts {
                ${hostLine hosts.homelab "lan"}
                ${hostLine hosts.homelab-test "lan"}
                ${hostLine hosts.homelab-test-foxtrot "lan"}
                fallthrough
              }
              import common
              import adblock
              import forward
            }

            . {
              view lan {
                expr incidr(client_ip(), '${cfg.tailscaleCidr}')
              }
              hosts {
                ${hostLine hosts.homelab "tailscale"}
                ${hostLine hosts.homelab-test "tailscale"}
                ${hostLine hosts.homelab-test-foxtrot "tailscale"}
                fallthrough
              }
              import common
              import adblock
              import forward
            }

            # CloudFlare upstream
            .:5301 {
              forward . tls://1.1.1.1 tls://1.0.0.1 {
                tls_servername cloudflare-dns.com
              }
            }

            # UncensoredDNS upstream
            .:5302 {
              forward . tls://91.239.100.100:853 {
                tls_servername anycast.uncensoreddns.org
              }
            }

            # Quad9 base DNS server
            .:5303 {
              forward . tls://9.9.9.9 tls://149.112.112.112 {
                tls_servername dns.quad9.net
              }
            }
          '';
        };

        resolved.enable = false;

        netdata.configDir."go.d/coredns.conf" = yaml.generate "coredns.conf" {
          jobs = [
            {
              name = "local";
              url = "http://localhost:9153/metrics";
            }
          ];
        };
      };

      networking.nameservers = ["127.0.0.1:${toString cfg.port}"];
      networking.firewall.allowedUDPPorts = [cfg.port];
    };
  });
  flake.modules.nixos.default = self.modules.nixos.dns;
}
