{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "cygwin-setup-bin";
  version = "2.905";

  src = fetchurl {
    url = "https://www.cygwin.com/setup-x86_64.exe";
    sha256 = "TdTUUx6OY63oSdqq9Ye6HBQwNocBdyyO5Con9OjDc+Q=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    install -D -m755 $src $out/bin/cygwin-setup.exe
  '';
}
