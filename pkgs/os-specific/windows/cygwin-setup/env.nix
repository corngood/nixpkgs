{ stdenv, cygwinSetupBin, cygwinRepo }:

stdenv.mkDerivation {
  pname = "cygwin-env";
  version = cygwinRepo.version;

  buildInputs = [ cygwinSetupBin ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    cygwin-setup -qBnL -l "$(cygpath -wa ${cygwinRepo}/share/cygwin-setup)" -R "$(cygpath -wa .)" -C base
    mkdir $out
    cp -r usr/* $out
    rm bin/cygwin1.dll
    cp -r bin lib $out
    CYGWIN+=\ winsymlinks:nativestrict ln -s /usr/bin/cygwin1.dll $out/bin
  '';

  dontFixup = true;
}
