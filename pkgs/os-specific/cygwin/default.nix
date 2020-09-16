{ newScope, recurseIntoAttrs, stdenv, fetchurl }: let

  callPackage = newScope self;

  arch = "x86_64";
  mirror = "http://cygwin.mirror.constant.com";

  mkPackage = { name, version, install, source ? null }:
    stdenv.mkDerivation rec {
      pname = name;
      inherit version;
      src = fetchurl {
        url = "${mirror}/${install.url}";
        inherit (install) sha512;
      };
      installPhase = ''
        cp -r . $out
      '';
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
    };

  mkPackages = stdenv.lib.mapAttrs (name: value:
    mkPackage (value // { inherit name; }));

  self = {
    packages = recurseIntoAttrs (mkPackages (import ./packages.nix));
  };
in self
