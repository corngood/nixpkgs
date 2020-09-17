{ lib
, config, overlays
, bootStages
, ...
}:

bootStages ++ [

  (prevStage: {
    inherit config overlays;
    stdenv = with prevStage; import ../generic {
      inherit (stdenv)
        fetchurlBoot
        shell
        initialPath;
      inherit
        config
        buildPlatform
        hostPlatform
        targetPlatform;
      # shell = "${bash}/bin/bash";
      # initialPath = import ../common-path.nix { pkgs = prevStage; };
      cc = import ../../build-support/cc-wrapper {
        nativeTools = false;
        nativeLibc = false;
        libc = cygwin.packages.cygwin-devel;
        cc = callPackage ../../development/compilers/gcc/9 {
          stdenv = stdenv // {
            cc = stdenv.cc // {
              libc = cygwin.packages.cygwin-devel;
              w32api-headers = cygwin.packages.w32api-headers;
              nativeLibc = false;
            };
          };
          noSysDirs = true;
          profiledCompiler = false;
          libcCross = null;
          isl = isl_0_17;
        } // { hardeningUnsupportedFlags = [ "fortify"]; };
        bintools = import ../../build-support/bintools-wrapper {
          name = "bintools";
          nativeTools = false;
          nativeLibc = false;
          libc = cygwin.packages.cygwin-devel;
          bintools = binutils-unwrapped;
          extraBuildCommands = ''
            echo "-L${cygwin.packages.w32api-runtime}/lib/w32api" > $out/nix-support/libc-ldflags
          '';
          inherit stdenvNoCC coreutils gnugrep;
        };
        inherit stdenvNoCC coreutils gnugrep;
      };
    };
  })

]
