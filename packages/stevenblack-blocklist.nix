{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "stevenblack-blocklist";
  version = "3.15.29";
  # https://github.com/StevenBlack/hosts/releases
  src = pkgs.fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = version;
    sha256 = "sha256-Ph0Wc7tl5FHZatSK9BNMZ8lNhGdJKx9X3+Px9MaYKyI=";
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
