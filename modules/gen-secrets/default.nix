{config, ...}: {
  flake.modules.nixos.default = config.flake.modules.nixos.gen-secrets;
  flake.modules.nixos.gen-secrets = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.gen-secrets;
    genSecrets =
      pkgs.writers.writePython3Bin
      "gen-secrets"
      {}
      (builtins.readFile ./gen-secrets.py);
  in {
    options.services.gen-secrets = {
      secretsDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/gen-secrets/secrets";
      };
      secrets = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
          options = {
            type = lib.mkOption {
              type = lib.types.enum ["password"];
              default = "password";
            };
            size = lib.mkOption {
              type = lib.types.int;
              default = 64;
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "0400";
            };

            # Outputs
            unit = lib.mkOption {type = lib.types.str;};
            unitName = lib.mkOption {type = lib.types.str;};
            path = lib.mkOption {type = lib.types.str;};
          };
          config = rec {
            unitName = "gen-secrets-${config._module.args.name}";
            unit = "${unitName}.service";
            path = "${cfg.secretsDir}/${config._module.args.name}";
          };
        }));
        default = {};
      };
    };
    config = lib.mkIf (cfg.secrets != {}) {
      systemd.tmpfiles.rules = [
        "d /var/lib/gen-secrets 0755 root root -"
        "d /var/lib/gen-secrets/secrets 0755 root root -"
      ];
      systemd.services =
        lib.mapAttrs' (name: secret: {
          name = secret.unitName;
          value = {
            description = "Generate ${name} secret";
            serviceConfig = {
              Type = "oneshot";
            };
            environment = {
              GEN_SECRETS_SPEC = builtins.toJSON ({
                  inherit name;
                }
                // secret);
            };
            script = lib.getExe genSecrets;
          };
        })
        cfg.secrets;
    };
  };
}
