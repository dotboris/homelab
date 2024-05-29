{pkgs, ...}: let
  version = "3.14.74";
in
  # https://github.com/StevenBlack/hosts/releases
  pkgs.fetchFromGitHub {
    name = "stevenback-blocklist-${version}";
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-wllEikCX/bMY/ZyRszXvar+AzYqmAx6fcjvcDJBkzfU=";
  }
