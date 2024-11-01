{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.14.128";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-IZVtXqjDWoQJdyTqw2zUKfpBxky1oix1gByPwcbNT+4=";
  };
  installPhase = ''
    mkdir -p $out
    cp hosts $out/hosts
  '';
  passthru.update = true;
}
