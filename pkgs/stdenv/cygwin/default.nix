{
  lib,
  localSystem,
  crossSystem,
  config,
  overlays,
  crossOverlays ? [ ],
}:

assert crossSystem == localSystem;
let
  bootStages = import ../. {
    inherit lib overlays;

    localSystem = lib.systems.elaborate "x86_64-linux";

    crossSystem = localSystem;
    crossOverlays = [ ];

    # Ignore custom stdenvs when cross compiling for compatibility
    # Use replaceCrossStdenv instead.
    config = builtins.removeAttrs config [ "replaceStdenv" ];
  };

in
bootStages
++ [

  # (
  #   prevStage:
  #   # previous stage5 stdenv; see stage3 comment regarding gcc,
  #   # which applies here as well.
  #   {
  #     inherit (prevStage) config overlays stdenv;
  #     selfBuild = true;
  #   }
  # )

  # Run Packages
  (
    prevStage:
    # previous stage4 stdenv; see stage3 comment regarding gcc,
    # which applies here as well.
    {
      inherit config overlays;
      allowCustomOverrides = true;
      stdenv = import ../generic rec {
        name = "stdenv-cygwin";

        buildPlatform = localSystem;
        hostPlatform = localSystem;
        targetPlatform = localSystem;
        inherit config;

        # preHook = commonPreHook;

        # initialPath = ((import ../generic/common-path.nix) { pkgs = prevStage; });
        initialPath =
          (
            (
              { pkgs }:
              [
                pkgs.coreutils
                pkgs.findutils
                pkgs.gawk
                pkgs.gnutar
                pkgs.gzip
                pkgs.bashNonInteractive
              ]
            )
            { pkgs = prevStage; }
          )
          # needed for cygwin1.dll
          ++ [ "/" ];

        extraNativeBuildInputs = [
          # Many tarballs come with obsolete config.sub/config.guess that don't recognize aarch64.
          prevStage.updateAutotoolsGnuConfigScriptsHook
        ];

        cc = prevStage.gcc;

        shell = cc.shell;

        # inherit (prevStage.stdenv) fetchurlBoot;
        fetchurlBoot = prevStage.fetchurl;

        extraAttrs = {
          # inherit bootstrapTools;
          shellPackage = prevStage.bash;
        };
        overrides =
          self: super:
          {
            inherit (prevStage)
              fetchurl
              gzip
              bzip2
              xz
              bashNonInteractive
              coreutils
              diffutils
              findutils
              gawk
              gnused
              gnutar
              gnupatch
              gnugrep
              patchelf
              attr
              acl
              zlib
              libunistring
              ;

            inherit (prevStage) pcre2;
            ${localSystem.libc} = prevStage.${localSystem.libc};

            # Hack: avoid libidn2.{bin,dev} referencing bootstrap tools.  There's a logical cycle.
            libidn2 = import ../../development/libraries/libidn2/no-bootstrap-reference.nix {
              inherit lib;
              inherit (prevStage) libidn2;
              inherit (self)
                stdenv
                runCommandLocal
                patchelf
                libunistring
                ;
            };

            gnumake = super.gnumake.override { inBootstrap = false; };
          }
          // lib.optionalAttrs (super.stdenv.targetPlatform == localSystem) {
            # Need to get rid of these when cross-compiling.
            inherit (prevStage) binutils binutils-unwrapped;
            gcc = cc;
          };
      };
    })

  # # Regular native packages
  # (
  #   somePrevStage:
  #   lib.last bootStages somePrevStage
  #   // {
  #     # It's OK to change the built-time dependencies
  #     allowCustomOverrides = true;
  #   }
  # )

  #   # Build tool Packages
  #   (vanillaPackages: {
  #     inherit config overlays;
  #     selfBuild = false;
  #     stdenv =
  #       assert vanillaPackages.stdenv.buildPlatform == localSystem;
  #       assert vanillaPackages.stdenv.hostPlatform == localSystem;
  #       assert vanillaPackages.stdenv.targetPlatform == localSystem;
  #       vanillaPackages.stdenv.override { targetPlatform = crossSystem; };
  #     # It's OK to change the built-time dependencies
  #     allowCustomOverrides = true;
  #   })

  #   # Run Packages
  #   (
  #     buildPackages:
  #     let
  #       adaptStdenv = if crossSystem.isStatic then buildPackages.stdenvAdapters.makeStatic else lib.id;
  #       stdenvNoCC = adaptStdenv (
  #         buildPackages.stdenv.override (old: rec {
  #           buildPlatform = localSystem;
  #           hostPlatform = crossSystem;
  #           targetPlatform = crossSystem;

  #           # Prior overrides are surely not valid as packages built with this run on
  #           # a different platform, and so are disabled.
  #           overrides = _: _: { };
  #           extraBuildInputs = [ ]; # Old ones run on wrong platform
  #           allowedRequisites = null;

  #           cc = null;
  #           hasCC = false;

  #           extraNativeBuildInputs =
  #             old.extraNativeBuildInputs
  #             ++ lib.optionals (hostPlatform.isLinux && !buildPlatform.isLinux) [ buildPackages.patchelf ]
  #             ++ lib.optional (
  #               let
  #                 f =
  #                   p:
  #                   !p.isx86
  #                   || builtins.elem p.libc [
  #                     "musl"
  #                     "wasilibc"
  #                     "relibc"
  #                   ]
  #                   || p.isiOS
  #                   || p.isGenode;
  #               in
  #               f hostPlatform && !(f buildPlatform)
  #             ) buildPackages.updateAutotoolsGnuConfigScriptsHook;
  #         })
  #       );
  #     in
  #     {
  #       inherit config;
  #       overlays = overlays ++ crossOverlays;
  #       selfBuild = false;
  #       inherit stdenvNoCC;
  #       stdenv =
  #         let
  #           inherit (stdenvNoCC) hostPlatform targetPlatform;
  #           baseStdenv = stdenvNoCC.override {
  #             # Old ones run on wrong platform

  #               buildPackages.targetPackages.apple-sdk
  #             ];

  #             hasCC = !stdenvNoCC.targetPlatform.isGhcjs;

  #             cc =
  #               if crossSystem.useiOSPrebuilt or false then
  #                 buildPackages.darwin.iosSdkPkgs.clang
  #               else if crossSystem.useAndroidPrebuilt or false then
  #                 buildPackages."androidndkPkgs_${crossSystem.androidNdkVersion}".clang
  #               else if
  #                 targetPlatform.isGhcjs
  #               # Need to use `throw` so tryEval for splicing works, ugh.  Using
  #               # `null` or skipping the attribute would cause an eval failure
  #               # `tryEval` wouldn't catch, wrecking accessing previous stages
  #               # when there is a C compiler and everything should be fine.
  #               then
  #                 throw "no C compiler provided for this platform"
  #               else if crossSystem.isDarwin then
  #                 buildPackages.llvmPackages.libcxxClang
  #               else if crossSystem.useLLVM or false then
  #                 buildPackages.llvmPackages.clang
  #               else if crossSystem.useZig or false then
  #                 buildPackages.zig.cc
  #               else if crossSystem.useArocc or false then
  #                 buildPackages.arocc
  #               else
  #                 buildPackages.gcc;

  #           };
  #         in
  #         if config ? replaceCrossStdenv then
  #           config.replaceCrossStdenv { inherit buildPackages baseStdenv; }
  #         else
  #           baseStdenv;
  #     }
  #   )

]
