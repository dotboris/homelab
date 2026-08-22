{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.externalHosts.pixie;
    vhost = config.homelab.reverseProxy.vhosts.pixie;
    defaultNode = cfg.nodes.${cfg.defaultNode};
  in {
    options.homelab.externalHosts.pixie = {
      enable = lib.mkEnableOption "pixie external host";
      defaultNode = lib.mkOption {type = lib.types.str;};
      nodes = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            localIp = lib.mkOption {type = lib.types.str;};
            remoteIp = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            httpPort = lib.mkOption {
              type = lib.types.port;
              default = 8006;
            };
          };
        });
        default = [];
      };
    };
    config = lib.mkIf cfg.enable {
      homelab.dns.extraHosts = lib.pipe cfg.nodes [
        (lib.mapAttrs' (name: node: {
          name = "${name}.lan";
          value = {
            lan = node.localIp;
            tailscale = node.remoteIp;
          };
        }))
      ];
      homelab.reverseProxy.vhosts.pixie = {};
      homelab.homepage.links = [
        {
          category = "system";
          title = "Pixie";
          icon = "proxmox.svg";
          description = "Proxmox VMs & Containers";
          urlVhost = "pixie";
        }
      ];
      services.traefik.dynamicConfigOptions.http = {
        routers.pixie = {
          rule = "Host(`${vhost.fqdn}`)";
          service = "pixie";
          tls = config.homelab.reverseProxy.tls.value;
        };
        serversTransports.pixie.insecureSkipVerify = true;
        services.pixie = {
          loadBalancer = {
            servers = [
              {
                url = "https://${defaultNode.localIp}:${toString defaultNode.httpPort}";
              }
            ];
            serversTransport = "pixie";
          };
        };
      };
    };
  };
}
