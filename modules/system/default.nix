{...}: {
  imports = [
    ./admin.nix
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      cores = 0; # use all cores
      max-jobs = "auto"; # use all cores
    };

    gc.automatic = true;
    optimise.automatic = true;
  };
}
