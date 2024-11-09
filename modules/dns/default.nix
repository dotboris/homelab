{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.homelab.dns;
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
      config = ''
        .:${toString cfg.port} {
          forward . 127.0.0.1:5301 127.0.0.1:5302 127.0.0.1:5303
          errors
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
