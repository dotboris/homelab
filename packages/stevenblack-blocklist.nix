{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.14.130";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-1LO6MzklwZ3ry3gi8ET129L7P2aRsAWOj1XeiNM6qHM=";
  };
  installPhase = ''
    mkdir -p $out
    cp hosts $out/hosts
  '';
  passthru.update = true;
}
