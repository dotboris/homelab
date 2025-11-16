{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.homelab.backups.github;
      syncGithubScript = pkgs.writeShellApplication {
        name = "sync-github-for-backups.sh";
        runtimeInputs = [
          pkgs.ghorg
          pkgs.git
        ];
        runtimeEnv = {
          # GitHub Auth
          GHORG_GITHUB_APP_ID = cfg.appId;
          GHORG_GITHUB_APP_INSTALLATION_ID = cfg.installationId;
          GHORG_GITHUB_APP_PEM_PATH = config.sops.secrets."backups/github/app-private-key".path;
          # Options
          GHORG_CLONE_TYPE = toString cfg.cloneType;
          GHORG_CLONE_WIKI = boolToString cfg.cloneWiki;
          GHORG_SKIP_ARCHIVED = boolToString cfg.skipArchived;
          GHORG_SKIP_FORKS = boolToString cfg.skipForks;
          GHORG_ABSOLUTE_PATH_TO_CLONE_TO = cfg.syncDir;
          GHORG_IGNORE_PATH = "/dev/null";
        };
        text = ''
          cd /
          ghorg clone ${cfg.githubOrg} \
            --scm github \
            --backup \
            --prune \
            --prune-no-confirm
        '';
      };
    in {
      options.homelab.backups.github = {
        enable = mkEnableOption "backup github repos";
        appId = mkOption {
          type = types.str;
          description = "GitHub app id used to authenticate";
        };
        installationId = mkOption {
          type = types.str;
          description = "Insatallation ID describing what org / user this app is installed in";
        };
        githubOrg = mkOption {
          type = types.str;
          description = "GitHub org or user to backup all repos from";
        };
        syncDir = mkOption {
          type = types.path;
          default = "/var/lib/homelab-backups/github";
        };
        cloneType = mkOption {
          type = types.enum ["org" "user"];
          default = "org";
        };
        cloneWiki = mkOption {
          type = types.bool;
          description = "Include Wiki as part of the backup";
          default = false;
        };
        skipArchived = mkOption {
          type = types.bool;
          description = "Do no backup archived repositories";
          default = false;
        };
        skipForks = mkOption {
          type = types.bool;
          description = "Do no backup forks";
          default = false;
        };
      };

      config = mkIf cfg.enable {
        sops.secrets."backups/github/app-private-key" = {
          owner = "backups";
        };
        systemd.tmpfiles.rules = [
          "d ${cfg.syncDir} 0700 backups backups"
        ];
        homelab.backups.recipes.github = self.lib.mkBackupRecipe pkgs {
          name = "github";
          paths = [cfg.syncDir];
          before = {
            shell = "bash";
            command = lib.getExe syncGithubScript;
          };
        };
      };
    };
}
