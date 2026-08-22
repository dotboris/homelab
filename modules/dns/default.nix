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
    cfg = config.homelab.dns;
    yaml = pkgs.formats.yaml {};
    hosts = let
      mkHost = {
        key,
        ips,
      }: let
        inherit (self.nixosConfigurations.${key}) config;
        host = self.hosts.${key};
      in {
        inherit ips;
        name = host.hostname;
        aliases =
          lib.mapAttrsToList (_: vhost: "${vhost.fqdn}.")
          config.homelab.reverseProxy.vhosts;
      };
    in {
      homelab = mkHost {
        key = "homelab";
        ips = {
          lan = "10.0.42.2";
          tailscale = "100.69.230.33";
        };
      };
      homelab-test = mkHost {
        key = "homelab-test";
        ips = {
          lan = "10.0.42.3";
          tailscale = "100.67.226.105";
        };
      };
      homelab-test-foxtrot = mkHost {
        key = "homelab-test-foxtrot";
        ips = {
          lan = "192.168.122.3";
          tailscale = "100.103.210.109";
        };
      };
    };
  in {
    options.homelab.dns = {
      enable = lib.mkEnableOption "dns server";
      port = lib.mkOption {
        type = lib.types.port;
        default = 53;
      };
      lanCidr = lib.mkOption {
        type = lib.types.str;
        description = "CIDR for the local network";
        default = "10.0.42.0/24";
      };
      tailscaleCidr = lib.mkOption {
        type = lib.types.str;
        description = "CIDR for the tailscale network";
        default = "100.0.0.0/8";
      };
      extraHosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            lan = lib.mkOption {type = lib.types.str;};
            tailscale = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        });
        default = {};
      };
    };

    config = lib.mkIf cfg.enable {
      services = {
        coredns = {
          enable = true;
          extraArgs = ["-dns.port=${toString cfg.port}"];
          package = self'.packages.coredns;
          config = let
            hostLine = host: variant: (
              lib.concatStringsSep " " ([host.ips.${variant} host.name] ++ host.aliases)
            );
            extraHostLines = extraHosts: attr: (
              lib.pipe extraHosts [
                (lib.mapAttrsToList (host: ips: let
                  ip = ips.${attr};
                in
                  lib.optionalString (ip != null) "${ip} ${host}"))
                lib.concatLines
              ]
            );
          in ''
            (adblock) {
              blocklist ${self'.packages.stevenblack-blocklist}/blocklist.txt {
                allowlist ${self'.packages.anudeepnd-allowlist}/domains/whitelist.txt
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
                ${extraHostLines cfg.extraHosts "lan"}
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
                ${extraHostLines cfg.extraHosts "tailscale"}
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
