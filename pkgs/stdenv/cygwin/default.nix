{
  lib,
  localSystem,
  crossSystem,
  config,
  overlays,
  crossOverlays ? [ ],
  bootstrapFiles ?
    let
      table = {
        x86_64-cygwin = {
          # import ./bootstrap-files/x86_64-pc-cygwin.nix;
          unpack = lib.toDerivation /nix/store/2g6dzrj4xlv9rdnbynlflk7s4ymsqy91-unpacked // {
            name = "unpacked";
            version = "foo";
          };
        };
      };
      files =
        table.${localSystem.system}
          or (throw "unsupported platform ${localSystem.system} for the cygwin stdenv");
    in
    files,
}:

assert crossSystem == localSystem;
let
  # bootStages = import ../. {
  #   inherit lib overlays;

  #   localSystem = lib.systems.elaborate "x86_64-linux";

  #   crossSystem = localSystem;
  #   crossOverlays = [ ];

  #   # Ignore custom stdenvs when cross compiling for compatibility
  #   # Use replaceCrossStdenv instead.
  #   config = builtins.removeAttrs config [ "replaceStdenv" ];
  # };

  bootStages = [ ];

  linkBootstrap = (
    attrs:
    derivation (
      attrs
      // {
        inherit (localSystem) system;
        name = attrs.name or (baseNameOf (builtins.elemAt attrs.paths 0));
        src = bootstrapFiles.unpack;
        builder = "${bootstrapFiles.unpack}/bin/bash";
        # this script will prefer to link files instead of copying them.
        # this prevents clang in particular, but possibly others, from calling readlink(argv[0])
        # and obtaining dependencies, ld(1) in particular, from there instead of $PATH.
        args = [ ../freebsd/linkBootstrap.sh ];
        PATH = "${bootstrapFiles.unpack}/bin";
        paths = attrs.paths;
      }
    )
  );

  # bashNonInteractive = linkBootstrap {
  #   paths = [
  #     "bin/bash"
  #     "bin/sh"
  #   ];
  #   shell = "bin/bash";
  #   shellPath = "/bin/bash";
  # };
  # binutils-unwrapped = linkBootstrap {
  #   name = "binutils";
  #   paths = map (str: "bin/" + str) [
  #     "ld"
  #     #"as"
  #     #"addr2line"
  #     "ar"
  #     #"c++filt"
  #     #"elfedit"
  #     #"gprof"
  #     #"objdump"
  #     "nm"
  #     "objcopy"
  #     "ranlib"
  #     "readelf"
  #     "size"
  #     "strings"
  #     "strip"
  #   ];
  # };
  bashNonInteractive = bootstrapFiles.unpack;
  binutils-unwrapped = bootstrapFiles.unpack;
  cocom-tool-set = bootstrapFiles.unpack;
  coreutils = bootstrapFiles.unpack;
  curl = bootstrapFiles.unpack;
  expand-response-params = bootstrapFiles.unpack;
  # gcc-unwrapped = linkBootstrap {
  #   name = "gcc";
  #   paths = map (str: "bin/" + str) [
  #     "gcc"
  #     "g++"
  #   ];
  # };
  gcc-unwrapped = bootstrapFiles.unpack;
  gnugrep = bootstrapFiles.unpack;

in
bootStages
++ [

  (
    prevStage:
    let
      name = "cygwin";

      initialPath = [
        bootstrapFiles.unpack
      ]
      # needed for cygwin1.dll
      ++ [ "/" ];

      shell = "${bashNonInteractive}/bin/bash";

      stdenvNoCC = import ../generic {
        inherit
          config
          initialPath
          shell
          fetchurlBoot
          ;
        name = "stdenvNoCC-${name}";
        buildPlatform = localSystem;
        hostPlatform = localSystem;
        targetPlatform = localSystem;
        cc = null;
      };

      fetchurlBoot = import ../../build-support/fetchurl {
        inherit lib stdenvNoCC curl;
        inherit (config) rewriteURL hashedMirrors;
      };

    in
    {
      inherit config overlays stdenvNoCC;
      stdenv = import ../generic rec {
        name = "stdenv-cygwin";

        buildPlatform = localSystem;
        hostPlatform = localSystem;
        targetPlatform = localSystem;
        inherit
          config
          initialPath
          fetchurlBoot
          shell
          ;

        hasCC = false;
        cc = null;

        overrides = self: super: {
          inherit cocom-tool-set;
          fetchurl = lib.makeOverridable fetchurlBoot;
          fetchgit = super.fetchgit.override {
            git = bootstrapFiles.unpack;
            cacert = null;
            git-lfs = null;
          };
        };
      };
    }
  )

  (prevStage: {
    inherit config overlays;
    inherit (prevStage) stdenvNoCC;

    stdenv = import ../generic rec {
      name = "stdenv-cygwin";

      buildPlatform = localSystem;
      hostPlatform = localSystem;
      targetPlatform = localSystem;
      inherit
        config
        ;
      inherit (prevStage.stdenv) fetchurlBoot initialPath shell;

      cc = lib.makeOverridable (import ../../build-support/cc-wrapper) {
        inherit lib;
        inherit (prevStage) stdenvNoCC;
        name = "${name}-cc";
        cc = gcc-unwrapped;
        isGNU = true;
        libc = prevStage.cygwin.newlib-cygwin-headers;
        inherit gnugrep coreutils;
        expand-response-params = "";
        nativeTools = false;
        nativeLibc = false;
        propagateDoc = false;
        runtimeShell = shell;
        bintools = lib.makeOverridable (import ../../build-support/bintools-wrapper) {
          inherit lib;
          inherit (prevStage) stdenvNoCC;
          name = "${name}-bintools";
          bintools = binutils-unwrapped;
          libc = prevStage.cygwin.newlib-cygwin-headers;
          inherit gnugrep coreutils;
          expand-response-params = "";
          nativeTools = false;
          nativeLibc = false;
          propagateDoc = false;
          runtimeShell = shell;
        };
      };

      overrides = self: super: {
        fetchurl = lib.makeOverridable fetchurlBoot;
        fetchgit = super.fetchgit.override {
          git = bootstrapFiles.unpack;
          cacert = null;
          git-lfs = null;
        };
        # __bootstrapFiles = bootstrapFiles;
        # __bootstrapPackages =
        #   (import ../generic/common-path.nix) { pkgs = prevStage; }
        #   ++ [
        #     gcc
        #     gcc.lib
        #   ]
        #   ++ (with prevStage; [
        #     curl
        #     curl.dev
        #     cygwin.newlib-cygwin
        #     cygwin.newlib-cygwin.bin
        #     cygwin.newlib-cygwin.dev
        #     cygwin.w32api
        #     cygwin.w32api.dev
        #     bintools-unwrapped
        #     gnugrep
        #     coreutils
        #     expand-response-params
        #   ]);
      };
    };
  })

  # (
  #   prevStage:
  #   let
  #     name = "cygwin";

  #     initialPath =
  #       ((import ../generic/common-path.nix) { pkgs = prevStage; })
  #       # needed for cygwin1.dll
  #       ++ [ "/" ];

  #     shell = "${prevStage.bashNonInteractive}/bin/bash";

  #     stdenvNoCC = import ../generic {
  #       inherit
  #         config
  #         initialPath
  #         shell
  #         fetchurlBoot
  #         ;
  #       name = "stdenvNoCC-${name}";
  #       buildPlatform = localSystem;
  #       hostPlatform = localSystem;
  #       targetPlatform = localSystem;
  #       cc = null;
  #     };

  #     fetchurlBoot = import ../../build-support/fetchurl {
  #       inherit lib stdenvNoCC;
  #       inherit (prevStage) curl;
  #       inherit (config) rewriteURL hashedMirrors;
  #     };

  #     gcc = (
  #       prevStage.gccFun {
  #         noSysDirs = true;
  #         majorMinorVersion = toString prevStage.default-gcc-version;
  #         targetPackages.stdenv.cc.bintools = prevStage.stdenv.cc.bintools;
  #       }
  #     );

  #   in
  #   {
  #     inherit config overlays stdenvNoCC;
  #     stdenv = import ../generic rec {
  #       name = "stdenv-cygwin";

  #       buildPlatform = localSystem;
  #       hostPlatform = localSystem;
  #       targetPlatform = localSystem;
  #       inherit
  #         config
  #         initialPath
  #         fetchurlBoot
  #         shell
  #         ;

  #       cc = lib.makeOverridable (import ../../build-support/cc-wrapper) {
  #         inherit lib stdenvNoCC;
  #         name = "${name}-cc";
  #         cc = gcc;
  #         isGNU = true;
  #         libc = prevStage.cygwin.newlib-cygwin;
  #         inherit (prevStage) gnugrep coreutils expand-response-params;
  #         nativeTools = false;
  #         nativeLibc = false;
  #         propagateDoc = false;
  #         runtimeShell = shell;
  #         bintools = lib.makeOverridable (import ../../build-support/bintools-wrapper) {
  #           inherit lib stdenvNoCC;
  #           name = "${name}-bintools";
  #           bintools = prevStage.bintools-unwrapped;
  #           libc = prevStage.cygwin.newlib-cygwin;
  #           inherit (prevStage) gnugrep coreutils expand-response-params;
  #           nativeTools = false;
  #           nativeLibc = false;
  #           propagateDoc = false;
  #           runtimeShell = shell;
  #         };
  #       };

  #       overrides = self: super: {
  #         fetchurl = lib.makeOverridable fetchurlBoot;
  #         __bootstrapFiles = bootstrapFiles;
  #         __bootstrapPackages =
  #           (import ../generic/common-path.nix) { pkgs = prevStage; }
  #           ++ [
  #             gcc
  #             gcc.lib
  #           ]
  #           ++ (with prevStage; [
  #             curl
  #             curl.dev
  #             cygwin.newlib-cygwin
  #             cygwin.newlib-cygwin.bin
  #             cygwin.newlib-cygwin.dev
  #             cygwin.w32api
  #             cygwin.w32api.dev
  #             bintools-unwrapped
  #             gnugrep
  #             coreutils
  #             expand-response-params
  #           ]);
  #       };
  #     };
  #   }
  # )
]
