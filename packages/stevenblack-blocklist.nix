{pkgs, ...}: let
  version = "3.14.125";
in
  # https://github.com/StevenBlack/hosts/releases
  pkgs.fetchFromGitHub {
    name = "stevenback-blocklist-${version}";
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-6bZhQRCGAeBzOXF8CRFDDG9fI0szycsR/6XDoFaYAjs=";
  }
