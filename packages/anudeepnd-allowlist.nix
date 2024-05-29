{pkgs, ...}: let
  version = "2.0.1";
in
  # https://github.com/anudeepND/whitelist/releases
  pkgs.fetchFromGitHub {
    name = "anudeepnd-allowlist-${version}";
    owner = "anudeepND";
    repo = "whitelist";
    rev = "v${version}";
    sha256 = "sha256-TWtYNxMU5gpe5Y4Th6tQaiOA09DBV7iJFPr9P7CAfag=";
  }
