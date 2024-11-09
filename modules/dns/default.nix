{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.dns;
  hosts = {
    homelab = {
      name = "homelab.lan";
      aliases = [
        "home.dotboris.io."
        "archive.dotboris.io."
        "feeds.dotboris.io."
        "netdata.dotboris.io."
        "traefik.dotboris.io."
        "ntfy.dotboris.io."
      ];
      ips = {
        lan = "10.0.42.2";
      };
    };
    homelab-test = {
      name = "homelab-test.lan";
      aliases = [
        "home-test.dotboris.io."
        "archive-test.dotboris.io."
        "feeds-test.dotboris.io."
        "netdata-test.dotboris.io."
        "traefik-test.dotboris.io."
        "ntfy-test.dotboris.io."
      ];
      ips = {
        lan = "10.0.42.3";
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
  };

  config = mkIf cfg.enable {
    services.coredns = {
      enable = true;
      extraArgs = ["-dns.port=${toString cfg.port}"];
      config = let
        hostLine = host: variant: (
          concatStringsSep " " ([host.ips.${variant} host.name] ++ host.aliases)
        );
      in ''
        (forward) {
          forward . 127.0.0.1:5301 127.0.0.1:5302 127.0.0.1:5303
        }

        (common) {
          errors
        }

        . {
          view lan {
            expr incidr(client_ip(), '127.0.0.0/24') || incidr(client_ip(), '10.0.42.0/24')
          }
          import common
          hosts {
            ${hostLine hosts.homelab "lan"}
            ${hostLine hosts.homelab-test "lan"}
            fallthrough
          }
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

    services.resolved.enable = false;
    networking.nameservers = ["127.0.0.1:${toString cfg.port}"];
    networking.firewall.allowedUDPPorts = [cfg.port];
  };
}
