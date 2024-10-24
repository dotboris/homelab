{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.14.125";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-6bZhQRCGAeBzOXF8CRFDDG9fI0szycsR/6XDoFaYAjs=";
  };
  installPhase = ''
    mkdir -p $out
    cp hosts $out/hosts
  '';
}
