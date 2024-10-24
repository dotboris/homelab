{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.14.126";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-t5kzFO1yjY7RrFLeK9MBbY7aRb2ThY1ytaXGVcC0Y+g=";
  };
  installPhase = ''
    mkdir -p $out
    cp hosts $out/hosts
  '';
}
