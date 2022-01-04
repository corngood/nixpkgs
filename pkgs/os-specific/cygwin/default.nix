{ newScope
, recurseIntoAttrs
, stdenvNoCC
, crossLibcStdenv
, lib
, fetchurl
, symlinkJoin
, zlib
, windows
}: let

  callPackage = newScope self;

  arch = "x86_64";
  # mirror = "http://cygwin.mirror.constant.com";
  mirror = "http://mirror.cpsc.ucalgary.ca/mirror/cygwin.com";

  mkPackage = { name, version, install, source ? null }:
    stdenvNoCC.mkDerivation rec {
      pname = name;
      inherit version;
      src = fetchurl {
        url = "${mirror}/${install.url}";
        inherit (install) sha512;
      };
      installPhase = ''
        cp -r . $out
      '';
      # stripping breaks lib archive headers
      # TODO: investigate why target aware tools aren't being used
      dontStrip = true;
      passthru = {
        source =
          if source != null
          then mkPackage {
            name = "${name}-source";
            inherit version;
            install = source;
          }
          else null;
      };

      meta = {
        platforms = lib.platforms.cygwin;
      };
    };

  mkPackages = lib.mapAttrs (name: value:
    mkPackage (value // { inherit name; }));

  self = rec {
    packages = recurseIntoAttrs (mkPackages (import ./packages.nix));

    newlib-cygwin = callPackage ../../development/misc/newlib/cygwin.nix {
      stdenv = crossLibcStdenv;
      zlib = zlib.override { stdenv = crossLibcStdenv; };
    };

    libc-boot = with packages; cygwin-devel // {
      w32api = w32api-runtime // {
        dev = w32api-headers;
      };
    };

    libc = newlib-cygwin // {
      w32api = windows.mingw_w64;
    };

  };
in self
