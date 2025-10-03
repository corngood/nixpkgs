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

  # Run Packages
  (
    prevStage:
    # previous stage4 stdenv; see stage3 comment regarding gcc,
    # which applies here as well.
    {
      inherit config overlays;
      stdenv = import ../generic rec {
        name = "stdenv-cygwin";

        buildPlatform = localSystem;
        hostPlatform = localSystem;
        targetPlatform = localSystem;
        inherit config;

        # preHook = commonPreHook;

        initialPath =
          ((import ../generic/common-path.nix) { pkgs = prevStage; })
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

  (prevStage: {
    inherit config overlays;

    stdenv = import ../generic rec {
      name = "stdenv-linux";

      buildPlatform = localSystem;
      hostPlatform = localSystem;
      targetPlatform = localSystem;
      inherit config;

      # preHook = commonPreHook;

      initialPath = ((import ../generic/common-path.nix) { pkgs = prevStage; });

      extraNativeBuildInputs = [
        # Many tarballs come with obsolete config.sub/config.guess that don't recognize aarch64.
        prevStage.updateAutotoolsGnuConfigScriptsHook
      ];

      cc = prevStage.gcc;

      shell = cc.shell;

      inherit (prevStage.stdenv) fetchurlBoot;

      extraAttrs = {
        # inherit bootstrapTools;
        shellPackage = prevStage.bash;
      };

      overrides = self: super: {
        inherit (prevStage)
          fetchurl
          ;
      };
    };
  })

]
