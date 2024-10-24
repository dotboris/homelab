{
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "anudeepnd-allowlist";
  version = "2.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "anudeepND";
    repo = "whitelist";
    rev = "v${version}";
    sha256 = "sha256-TWtYNxMU5gpe5Y4Th6tQaiOA09DBV7iJFPr9P7CAfag=";
  };
  installPhase = ''
    mkdir -p $out/domains
    cp domains/whitelist.txt $out/domains/whitelist.txt
  '';
}
