{...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    ...
  }: let
    cfg = config.homelab.auth;
    autheliaCfg = config.services.authelia.instances.main;
  in {
    options.homelab.auth = {
      oidcClientsDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/authelia-oidc-clients";
      };
      oidcClients = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({config, ...}: let
          inherit (config._module.args) name;
        in {
          options = {
            authorizationPolicy = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
              default = null;
            };
            beforeUnits = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
            };
            group = lib.mkOption {
              type = lib.types.str;
            };
            settings = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
            # Outputs
            dir = lib.mkOption {
              type = lib.types.path;
              internal = true;
            };
            clientIdPath = lib.mkOption {
              type = lib.types.path;
              internal = true;
            };
            clientSecretPath = lib.mkOption {
              type = lib.types.path;
              internal = true;
            };
            clientSecretHashPath = lib.mkOption {
              type = lib.types.path;
              internal = true;
            };
          };
          config = rec {
            dir = "${cfg.oidcClientsDir}/${name}";
            clientIdPath = "${dir}/client-id";
            clientSecretPath = "${dir}/client-secret";
            clientSecretHashPath = "${dir}/client-secret-hash";
          };
        }));
        default = {};
      };
    };
    config = lib.mkIf cfg.enable {
      services.authelia.instances.main.settings.identity_providers.oidc = {
        authorization_policies = lib.pipe cfg.oidcClients [
          (lib.filterAttrs (_: client: client.authorizationPolicy != null))
          (lib.mapAttrs' (name: client: {
            name = "oidc-client-${name}";
            value = client.authorizationPolicy;
          }))
        ];
        clients =
          lib.mapAttrsToList
          (name: client:
            client.settings
            // {
              client_id = "{{ secret `${client.clientIdPath}` }}";
              client_name = name;
              client_secret = "{{ secret `${client.clientSecretHashPath}` }}";
              authorization_policy =
                lib.mkIf (client.authorizationPolicy != null) "oidc-client-${name}";
            })
          cfg.oidcClients;
      };
      systemd = {
        tmpfiles.rules =
          lib.mapAttrsToList (
            _: client: "d ${client.dir} 0550 ${autheliaCfg.user} ${client.group}"
          )
          cfg.oidcClients;
        services =
          lib.mapAttrs' (name: client: {
            name = "authelia-oidc-client-${name}";
            value = {
              description = "Setup '${name}' OIDC client in Authelia";
              wantedBy = ["authelia.service"] ++ client.beforeUnits;
              unitConfig.Before = ["authelia.service"] ++ client.beforeUnits;
              serviceConfig.Type = "oneshot";
              path = [
                autheliaCfg.package
              ];
              environment = {
                inherit
                  (client)
                  clientIdPath
                  clientSecretPath
                  clientSecretHashPath
                  group
                  ;
              };
              script = ''
                if [ ! -f "$clientIdPath" ]; then
                  echo "Generating client id"
                  # Prepare file with right permissions
                  install -o authelia -g "$group" -m 0440 /dev/null "$clientIdPath"
                  # Set secret value
                  authelia crypto rand --length 72 --charset rfc3986 \
                    | grep -oP '(?<=^Random Value: ).*$' \
                    > "$clientIdPath"
                  echo "Wrote $clientIdPath"
                fi
                if [ ! -f "$clientSecretPath" ] || [ ! -f "$clientSecretHashPath" ]; then
                  echo "Generating client secret"
                  generated="$(
                    authelia crypto hash generate pbkdf2 \
                      --variant sha512 \
                      --random \
                      --random.length 72 \
                      --random.charset rfc3986
                  )"

                  # Prepare file with right permissions
                  install -o authelia -g "$group" -m 0440 /dev/null "$clientSecretPath"
                  # Extract raw secret value
                  grep -oP '(?<=^Random Password: ).*$' <<< "$generated" > "$clientSecretPath"
                  echo "Wrote $clientSecretPath"

                  # Prepare file with right permissions
                  install -o authelia -g "$group" -m 0440 /dev/null "$clientSecretHashPath"
                  # Extract digest value
                  grep -oP '(?<=^Digest: ).*$' <<< "$generated" > "$clientSecretHashPath"
                  echo "Wrote $clientSecretHashPath"
                fi
              '';
            };
          })
          cfg.oidcClients;
      };
    };
  };
}
