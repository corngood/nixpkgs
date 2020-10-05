{ stdenv, cygwinSetupBin }:

stdenv.mkDerivation {
  pname = "cygwin-repo";
  version = "20200909";

  buildInputs = [ cygwinSetupBin ];

  dontUnpack = true;
  dontBuild = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "qedUEQy/KeaeDBA6BBGqfLnip3uduEglJZ9sYLZOejQ=";

  installPhase = ''
    cygwin-setup -qBnD -l "$(cygpath -wa repo)" -R "$(cygpath -wa root)" -C base
    mkdir -p $out/share/cygwin-setup
    cp -r repo/*/ $out/share/cygwin-setup
  '';

  dontFixup = true;
}
