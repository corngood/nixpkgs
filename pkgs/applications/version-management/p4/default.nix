{ stdenv, fetchurl, lib, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "p4";
  version = "2021.1.2179737";

  src = fetchurl {
    url = "http://web.archive.org/web/20210910002004/https://cdist2.perforce.com/perforce/r21.1/bin.linux26x86_64/helix-core-server.tgz";
    sha256 = "038zhpwcgwvyrr5d4vaq778107095narywpvivsykfpjg0wxcw1s";
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
