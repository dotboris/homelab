{self, ...}: {
  flake.modules.nixos.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.auth;
    srcDir = "/var/lib/lldap";
    syncDir = "/var/lib/lldap-backup";
    script = pkgs.writeShellApplication {
      name = "prepare-lldap-backup";
      runtimeEnv = {
        inherit srcDir syncDir;
      };
      text = ''
        cp \
          --recursive \
          --preserve=mode,timestamps \
          --target-directory="$syncDir" \
          "$srcDir"/*
        chown -R backups:backups "$syncDir"
      '';
    };
  in {
    config = lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${syncDir} 0750 backups backups"
      ];
      security.sudo.extraRules = [
        {
          users = ["backups"];
          runAs = "root:backups";
          commands = [
            {
              command = "${lib.getExe script}";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
      homelab.backups.recipes.lldap = self.lib.mkBackupRecipe pkgs {
        name = "lldap";
        paths = [syncDir];
        before = {
          shell = "bash";
          command = ''
            /run/wrappers/bin/sudo \
              -u root -g backups \
              ${lib.escapeShellArg (lib.getExe script)}
          '';
        };
      };
    };
  };
}
