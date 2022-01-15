{ lib
, config, overlays
, bootStages
, ...
}:

let
  nativePrefix = "/usr";

  withLibcBoot = prevStage: {
    inherit config overlays;
    stdenv = with prevStage; import ../generic {
      inherit config;
      inherit (stdenv)
        buildPlatform
        hostPlatform
        targetPlatform
        initialPath
        shell
        fetchurlBoot
        preHook
        extraNativeBuildInputs
        ;
      cc = import ../../build-support/cc-wrapper {
        name = "cc-native";
        nativeTools = true;
        nativeLibc = false;
        libc = cygwin.libc-boot;
        inherit lib nativePrefix;
        bintools = import ../../build-support/bintools-wrapper {
          name = "bintools-native";
          inherit lib stdenvNoCC nativePrefix;
          nativeTools = true;
          nativeLibc = false;
          libc = cygwin.libc-boot;
        };
        inherit stdenvNoCC;
      };
    };
  };

  stageFun = prevStage: {
    inherit config overlays;
    stdenv = with prevStage; import ../generic {
      inherit config;
      inherit (stdenv)
        buildPlatform
        hostPlatform
        targetPlatform
        ;
      fetchurlBoot = fetchurl;
      shell = bash + "/bin/bash";
      preHook = ''
        shopt -s expand_aliases
        export lt_cv_deplibs_check_method=pass_all
        export gl_cv_have_weak=no
        export gl_cv_ld_autoimport=no
      '';
      extraNativeBuildInputs = [
        ../cygwin/all-buildinputs-as-runtimedep.sh
      ] ++ (if system == "i686-cygwin" then [
        ../cygwin/rebase-i686.sh
      ] else if system == "x86_64-cygwin" then [
        ../cygwin/rebase-x86_64.sh
      ] else []);
      extraBuildInputs = [
        (stdenvNoCC.mkDerivation {
          name = "cygwin1";
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            CYGWIN+=\ winsymlinks:nativestrict ln -s /usr/bin/{cygwin1.dll,gencat.exe} $out/bin
          '';
        })
      ];
      initialPath = import ../common-path.nix { pkgs = prevStage; };
      cc = import ../../build-support/cc-wrapper {
        nativeTools = false;
        nativeLibc = false;
        libc = cygwin.libc-boot;
        # gcc 11 was broken but I forget why
        # TODO: find out
        cc = callPackage ../../development/compilers/gcc/10 {
          noSysDirs = true;
          libcCross = null;
          isl = isl_0_17;
        # } // { hardeningUnsupportedFlags = [ "fortify" ]; };
        };
        bintools = import ../../build-support/bintools-wrapper {
          name = "bintools";
          nativeTools = false;
          nativeLibc = false;
          libc = cygwin.libc-boot;
          bintools = binutils-unwrapped;
          extraBuildCommands = ''
            echo "-L${cygwin.packages.w32api-runtime}/lib/w32api" > $out/nix-support/libc-ldflags
          '';
          inherit stdenvNoCC coreutils gnugrep lib;
        };
        inherit stdenvNoCC coreutils gnugrep lib;
      };
    };
  };

in bootStages ++ [
  withLibcBoot

  # The previous stage still has dependencies on /usr/bin: cygwin1.dll, and any
  # libraries found by configuration (e.g. -lintl)
  (prevStage: stageFun prevStage)

  # This one should be free of dependencies on /usr
  (prevStage: stageFun prevStage)

]
