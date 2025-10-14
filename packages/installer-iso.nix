{inputs, ...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    packages.installer-iso = let
      consts = import ../consts.nix;
      module = {...}: {
        imports = [
          inputs.nixos-images.nixosModules.image-installer
        ];

        # Bake in my SSH key so that I can ssh in without doing the password dance
        users.users.root.openssh.authorizedKeys.keys = consts.dotboris.ssh.pubKeys;

        environment.systemPackages = [
          # Image alrady ships disko but it's the nipkgs version not the one from
          # the flake. This ensures that we use the same version everywhere.
          inputs'.disko.packages.disko
        ];

        # Image enables bcachefs by default but it causes an assertion error. Not
        # sure why honestly but I don't think that we use bcachefs at all.
        boot.supportedFilesystems.bcachefs = false;

        nix.settings = {
          experimental-features = ["nix-command" "flakes"];

          cores = 0; # use all cores
          max-jobs = "auto"; # use all cores
        };
      };
    in
      (pkgs.nixos [module]).config.system.build.isoImage;
  };
}
