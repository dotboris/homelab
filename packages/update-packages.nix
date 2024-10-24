{pkgs, ...}:
pkgs.writeShellApplication {
  name = "update-packages";
  runtimeInputs = [pkgs.nix-update];
  text = ''
    nix-update -F anudeepnd-allowlist
    nix-update -F stevenblack-blocklist
  '';
}
