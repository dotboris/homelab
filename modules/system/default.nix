{pkgs, ...}: {
  imports = [
    ./admin.nix
  ];

  environment = {
    systemPackages = [
      pkgs.busybox # most of the base utilities
      pkgs.htop
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.useNetworkd = true;
  systemd.network.enable = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      cores = 0; # use all cores
      max-jobs = "auto"; # use all cores

      trusted-users = ["root" "@wheel"];
    };

    gc.automatic = true;
    optimise.automatic = true;
  };
}
