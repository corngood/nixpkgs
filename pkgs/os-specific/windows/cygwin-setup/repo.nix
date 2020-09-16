{ stdenv, cygwinSetupBin }:

stdenv.mkDerivation {
  pname = "cygwin-repo";
  version = "20200909";

  buildInputs = [ cygwinSetupBin ];

  dontUnpack = true;
  dontBuild = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "QB1NGNAz7BVmq9wF5vtBQnRS9NA6eV/zj/am/NibM48=";

  installPhase = ''
    cygwin-setup -qBnD -l "$(cygpath -wa repo)" -R "$(cygpath -wa root)" -C base
    mkdir -p $out/share/cygwin-setup
    cp -r repo/*/ $out/share/cygwin-setup
  '';

  dontFixup = true;
}
