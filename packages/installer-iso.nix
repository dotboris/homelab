{
  pkgs,
  system,
  inputs,
  ...
}: let
  consts = import ../consts.nix;
  nixos = pkgs.nixos [
    inputs.nixos-images.nixosModules.image-installer
    {
      # Bake in my SSH key so that I can ssh in without doing the password dance
      users.users.root.openssh.authorizedKeys.keys = [consts.dotborisSshPubkey];
    }
  ];
in
  nixos.config.system.build.isoImage
