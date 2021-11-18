{ stdenv, fetchurl, lib, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "p4";
  version = "2021.2.2201121";

  src = fetchurl {
    url = "http://web.archive.org/web/20211118024943/https://cdist2.perforce.com/perforce/r21.2/bin.linux26x86_64/helix-core-server.tgz";
    sha256 = "0bvh83dlparsdz9fyq6qb0m1k1c37kxgjz17njnkqa7vj3cwidsa";
  };

  sourceRoot = ".";

  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    cp p4 p4broker p4d p4p $out/bin
  '';

  meta = {
    description = "Perforce Command-Line Client";
    homepage = "https://www.perforce.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ corngood ];
  };
}
