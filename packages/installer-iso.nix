{
  pkgs,
  system,
  inputs,
  ...
}: let
  consts = import ../consts.nix;

  # NixOS module with customized configuration
  module = {...}: {
    # Bake in my SSH key so that I can ssh in without doing the password dance
    users.users.root.openssh.authorizedKeys.keys = [consts.dotborisSshPubkey];

    environment.systemPackages = [
      inputs.disko.packages.${system}.disko
    ];

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];

      cores = 0; # use all cores
      max-jobs = "auto"; # use all cores
    };
  };

  nixos = pkgs.nixos [
    inputs.nixos-images.nixosModules.image-installer
    module
  ];
in
  nixos.config.system.build.isoImage
