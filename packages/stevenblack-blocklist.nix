{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.16.24";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-LL91oKfSC1TV+bFwFFqnrDnbDnn+FukaFEQ8Ma4BJjo=";
  };
  # Clean up hosts file so that it's only a list of domains. We need to:
  # - Remove some generic host entries for localhost & the like
  # - Remove comments
  # - Remove empty lines
  # - Remove the ip prefix (0.0.0.0)
  buildPhase = ''
    sed -E \
      -e '/^0\.0\.0\.0/!d' \
      -e 's/^0\.0\.0\.0 (.+)$/\1/' \
      -e '/^0\.0\.0\.0$/d' \
      hosts \
      > blocklist.txt
  '';
  installPhase = ''
    mkdir -p $out
    cp blocklist.txt $out/blocklist.txt
  '';
  passthru.update = true;
}
