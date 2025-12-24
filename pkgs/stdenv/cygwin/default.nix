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
          unpack = lib.toDerivation (import ../../../bootstrap.nix) // {
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
        version = bootstrapFiles.unpack.version;
        src = bootstrapFiles.unpack;
        builder = "${bootstrapFiles.unpack}/bin/bash";
        args = [ ./linkBootstrap.sh ];
        PATH = "${bootstrapFiles.unpack}/bin";
        paths = attrs.paths;
      }
    )
  );

  bashNonInteractive = linkBootstrap {
    paths = [
      "bin/bash"
      "bin/sh"
    ];
    shell = "bin/bash";
    shellPath = "/bin/bash";
  };
  binutils-unwrapped = linkBootstrap {
    name = "binutils";
    paths = map (str: "bin/" + str) [
      "ld"
      "as"
      "addr2line"
      "ar"
      "c++filt"
      "dlltool"
      "elfedit"
      "gprof"
      "objdump"
      "nm"
      "objcopy"
      "ranlib"
      "readelf"
      "size"
      "strings"
      "strip"
      "windres"
    ];
  };
  bzip2 = linkBootstrap { paths = [ "bin/bzip2" ]; };
  coreutils = linkBootstrap {
    name = "coreutils";
    paths = map (str: "bin/" + str) [
      "base64"
      "basename"
      "cat"
      "chcon"
      "chgrp"
      "chmod"
      "chown"
      "chroot"
      "cksum"
      "comm"
      "cp"
      "csplit"
      "cut"
      "date"
      "dd"
      "df"
      "dir"
      "dircolors"
      "dirname"
      "du"
      "echo"
      "env"
      "expand"
      "expr"
      "factor"
      "false"
      "fmt"
      "fold"
      "groups"
      "head"
      "hostid"
      "id"
      "install"
      "join"
      "kill"
      "link"
      "ln"
      "logname"
      "ls"
      "md5sum"
      "mkdir"
      "mkfifo"
      "mknod"
      "mktemp"
      "mv"
      "nice"
      "nl"
      "nohup"
      "nproc"
      "numfmt"
      "od"
      "paste"
      "pathchk"
      "pinky"
      "pr"
      "printenv"
      "printf"
      "ptx"
      "pwd"
      "readlink"
      "realpath"
      "rm"
      "rmdir"
      "runcon"
      "seq"
      "shred"
      "shuf"
      "sleep"
      "sort"
      "split"
      "stat"
      "stty"
      "sum"
      "tac"
      "tail"
      "tee"
      "test"
      "timeout"
      "touch"
      "tr"
      "true"
      "truncate"
      "tsort"
      "tty"
      "uname"
      "unexpand"
      "uniq"
      "unlink"
      "users"
      "vdir"
      "wc"
      "who"
      "whoami"
      "yes"
      "["
    ];
  };
  curl = linkBootstrap {
    paths = [
      "bin/curl"
    ];
  };
  diffutils = linkBootstrap {
    name = "diffutils";
    paths = map (str: "bin/" + str) [
      "diff"
      "cmp"
      #"diff3"
      #"sdiff"
    ];
  };
  # expand-response-params = bootstrapFiles.unpack;
  file = linkBootstrap {
    name = "file";
    paths = [ "bin/file" ];
  };
  findutils = linkBootstrap {
    name = "findutils";
    paths = [
      "bin/find"
      "bin/xargs"
    ];
  };
  gawk = linkBootstrap {
    paths = [
      "bin/awk"
      "bin/gawk"
    ];
  };
  gcc-unwrapped = linkBootstrap {
    name = "gcc";
    paths = map (str: "bin/" + str) [
      "gcc"
      "g++"
    ];
  };
  git = linkBootstrap { paths = [ "bin/git" ]; };
  gnugrep = linkBootstrap {
    paths = [
      "bin/grep"
      "bin/egrep"
      "bin/fgrep"
    ];
  };
  gnumake = linkBootstrap { paths = [ "bin/make" ]; };
  gnused = linkBootstrap { paths = [ "bin/sed" ]; };
  gnutar = linkBootstrap { paths = [ "bin/tar" ]; };
  gzip = linkBootstrap {
    paths = [
      "bin/gzip"
      #"bin/gunzip"
    ];
  };
  libc = linkBootstrap {
    name = "libc";
    paths = [ "lib" ];
  };
  patch = linkBootstrap { paths = [ "bin/patch" ]; };
  xz = linkBootstrap { paths = [ "bin/xz" ]; };

in
bootStages
++ [

  (
    prevStage:
    let
      name = "cygwin";

      initialPath = [
        coreutils
        diffutils
        gnutar
        file
        findutils
        gnumake
        gnused
        gnugrep
        gawk
        patch
        bashNonInteractive
        gzip
        bzip2
        xz
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
          fetchurl = lib.makeOverridable fetchurlBoot;
          fetchgit = super.fetchgit.override {
            inherit git;
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
      inherit config;
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
          inherit git;
          cacert = null;
          git-lfs = null;
        };
      };
    };
  })

  (prevStage: {
    inherit config overlays;
    inherit (prevStage) stdenvNoCC;

    stdenv = import ../generic rec {
      name = "stdenv-cygwin";

      buildPlatform = localSystem;
      hostPlatform = localSystem;
      targetPlatform = localSystem;
      inherit config;
      inherit (prevStage.stdenv) fetchurlBoot initialPath shell;

      cc = lib.makeOverridable (import ../../build-support/cc-wrapper) {
        inherit lib;
        inherit (prevStage) stdenvNoCC;
        name = "${name}-cc";
        cc = gcc-unwrapped;
        isGNU = true;
        libc = libc // {
          inherit (prevStage.cygwin) w32api;
        };
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
          libc = libc // {
            inherit (prevStage.cygwin) w32api;
          };
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
          inherit git;
          cacert = null;
          git-lfs = null;
        };
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
