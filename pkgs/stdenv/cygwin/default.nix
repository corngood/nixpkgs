{ lib
, config, overlays
, bootStages
, ...
}:

bootStages ++ [

  # # This stage still has dependencies on /usr/bin: cygwin1.dll, and any
  # # libraries found by configuration (e.g. -lintl)
  # # Therefore, /usr is still in initialPath, and the native shell is still used.
  # (prevStage: {
  #   inherit config overlays;
  #   stdenv = with prevStage; import ../generic {
  #     inherit (stdenv)
  #       fetchurlBoot
  #       shell
  #       ;
  #     inherit
  #       config
  #       buildPlatform
  #       hostPlatform
  #       targetPlatform
  #       ;
  #     preHook = ''
  #       shopt -s expand_aliases
  #       export Lt_cv_deplibs_check_method=pass_all
  #     '';
  #     extraNativeBuildInputs = [
  #       ../cygwin/all-buildinputs-as-runtimedep.sh
  #     ] ++ (if system == "i686-cygwin" then [
  #       ../cygwin/rebase-i686.sh
  #     ] else if system == "x86_64-cygwin" then [
  #       ../cygwin/rebase-x86_64.sh
  #     ] else []);
  #     extraBuildInputs = [
  #       (stdenvNoCC.mkDerivation {
  #         name = "cygwin1";
  #         dontUnpack = true;
  #         installPhase = ''
  #           mkdir -p $out/bin
  #           CYGWIN+=\ winsymlinks:nativestrict ln -s /usr/bin/cygwin1.dll $out/bin
  #         '';
  #       })
  #     ];
  #     initialPath = import ../common-path.nix { pkgs = prevStage; } ++ [ "/usr" ];
  #     cc = import ../../build-support/cc-wrapper {
  #       nativeTools = false;
  #       nativeLibc = false;
  #       libc = cygwin.packages.cygwin-devel;
  #       cc = callPackage ../../development/compilers/gcc/9 {
  #         stdenv = stdenv // {
  #           cc = stdenv.cc // {
  #             libc = cygwin.packages.cygwin-devel;
  #             w32api-headers = cygwin.packages.w32api-headers;
  #             nativeLibc = false;
  #           };
  #         };
  #         noSysDirs = true;
  #         profiledCompiler = false;
  #         libcCross = null;
  #         isl = isl_0_17;
  #       } // { hardeningUnsupportedFlags = [ "fortify"]; };
  #       extraBuildCommands = ''
  #         echo 'PATH=$PATH:/usr/bin' >> $out/nix-support/utils.bash
  #       '';
  #       bintools = import ../../build-support/bintools-wrapper {
  #         name = "bintools";
  #         nativeTools = false;
  #         nativeLibc = false;
  #         libc = cygwin.packages.cygwin-devel;
  #         bintools = binutils-unwrapped;
  #         extraBuildCommands = ''
  #           echo "-L${cygwin.packages.w32api-runtime}/lib/w32api" > $out/nix-support/libc-ldflags
  #           echo 'PATH=$PATH:/usr/bin' >> $out/nix-support/utils.bash
  #         '';
  #         inherit stdenvNoCC coreutils gnugrep;
  #       };
  #       inherit stdenvNoCC coreutils gnugrep;
  #     };
  #   };
  # })

]
