{...}: {
  flake.modules.nixos.default = {...}: {
    config.homelab = {
      # Centrally assign ports. We could do this in each module but this makes
      # it super easy to track which ports got where and to add new ones. Keep
      # things in port order instead of grouped by feature / service.
      homepage.port = 8001;
      monitoring.netdata.port = 8002;
      monitoring.traefik.exporterPort = 8003;
      feeds.httpPort = 8004;
      documents-archive.port = 8005;
      monitoring.ntfy.port = 8006;
      nextcloud.port = 8007;
      search.port = 8008;
      music.port = 8009;
      files.port = 8010;
      auth.port = 8011;
      auth.ldapAdminPort = 8012;
      books.port = 8013;
    };
  };
}
