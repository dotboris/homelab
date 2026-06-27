{self, ...}: {
  flake.modules.nixos.default = {
    lib,
    config,
    pkgs,
    ...
  }: let
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
        GHORG_CLONE_WIKI = lib.boolToString cfg.cloneWiki;
        GHORG_FETCH_GIT_LFS = lib.boolToString cfg.fetchGitLfs;
        GHORG_SKIP_ARCHIVED = lib.boolToString cfg.skipArchived;
        GHORG_SKIP_FORKS = lib.boolToString cfg.skipForks;
        GHORG_ABSOLUTE_PATH_TO_CLONE_TO = cfg.syncDir;
        GHORG_IGNORE_PATH = "/dev/null";
        GHORG_ONLY_PATH = "/dev/null";
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
      enable = lib.mkEnableOption "backup github repos";
      appId = lib.mkOption {
        type = lib.types.str;
        description = "GitHub app id used to authenticate";
      };
      installationId = lib.mkOption {
        type = lib.types.str;
        description = "Insatallation ID describing what org / user this app is installed in";
      };
      githubOrg = lib.mkOption {
        type = lib.types.str;
        description = "GitHub org or user to backup all repos from";
      };
      syncDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/homelab-backups/github";
      };
      cloneType = lib.mkOption {
        type = lib.types.enum ["org" "user"];
        default = "org";
      };
      cloneWiki = lib.mkOption {
        type = lib.types.bool;
        description = "Include Wiki as part of the backup";
        default = false;
      };
      fetchGitLfs = lib.mkOption {
        type = lib.types.bool;
        description = "Backup Git LFS contents as well";
        default = true;
      };
      skipArchived = lib.mkOption {
        type = lib.types.bool;
        description = "Do no backup archived repositories";
        default = false;
      };
      skipForks = lib.mkOption {
        type = lib.types.bool;
        description = "Do no backup forks";
        default = false;
      };
    };

    config = lib.mkIf cfg.enable {
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
