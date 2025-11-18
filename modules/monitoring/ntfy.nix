{...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.homelab.monitoring.ntfy;
      vhost = config.homelab.reverseProxy.vhosts.ntfy;
    in {
      options.homelab.monitoring.ntfy = {
        port = mkOption {
          type = types.port;
        };
      };

      config = {
        homelab = {
          reverseProxy.vhosts.ntfy = {};
          homepage.links = [
            {
              category = "system";
              title = "Alerts";
              icon = "ntfy.svg";
              description = "ntfy.sh";
              urlVhost = "ntfy";
            }
          ];
        };

        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = "https://${vhost.fqdn}";
            listen-http = ":${toString cfg.port}";
            behind-proxy = true;
          };
        };

        # OnSuccess=/OnFailure= unit handler for ntfy. Depending on the result,
        # will send a message to ntfy.
        #
        # Format is `ntfy-handler@{topic}--{comment}.service`:
        # - `topic` - The ntfy topic to send the message to
        # - `command` - Arbitrary value. Used to make instance name unique.
        #
        # IMPORTANT: The instance name (everything after `@` must be unique).
        #   Use `comment` to achieve this.
        systemd.services."ntfy-handler@" = {
          serviceConfig.Type = "oneshot";
          path = [pkgs.curl];
          scriptArgs = "%i";
          script = ''
            IFS=-- read -ra args <<< "$1"
            topic="''${args[0]}"

            priority=3
            tag=tada
            title="$MONITOR_UNIT completed"
            if [[ "$MONITOR_EXIT_STATUS" != 0 ]]; then
              priority=5
              tag=rotating_light
              title="$MONITOR_UNIT failed"
            fi

            (
              echo **Result**:
              echo '```'
              env | grep '^MONITOR_'
              echo '```'
              echo
              echo **Logs**:
              echo '```'
              journalctl --output=cat --invocation="$MONITOR_INVOCATION_ID"
              echo '```'
            ) | curl --fail --silent --show-error \
              -X POST "https://${vhost.fqdn}/$topic" \
              -H "Priority: $priority" \
              -H "Title: $title" \
              -H "Tag: $tag" \
              -H "Markdown: yes" \
              --data-binary @-
          '';
        };

        services.traefik.dynamicConfigOptions.http = {
          routers.ntfy = {
            rule = "Host(`${vhost.fqdn}`)";
            service = "ntfy";
            tls = config.homelab.reverseProxy.tls.value;
          };

          services.ntfy = {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString cfg.port}";}];
            };
          };
        };
      };
    };
}
