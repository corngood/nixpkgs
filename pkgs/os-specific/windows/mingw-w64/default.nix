{ lib, stdenv, windows, fetchurl }:

let
  version = "9.0.0";
in stdenv.mkDerivation {
  pname = "mingw-w64";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/mingw-w64/mingw-w64-v${version}.tar.bz2";
    sha256 = "10a15bi4lyfi0k0haj0klqambicwma6yi7vssgbz8prg815vja8r";
  };

  outputs = [ "out" "dev" ];

  configureFlags =
    if stdenv.targetPlatform.isCygwin
    then [
      "--enable-w32api"
      "--enable-sdk=all"
    ] ++ (if stdenv.targetPlatform.is64bit
          then [ "--disable-lib32" "--enable-lib64" ]
          else [ "--disable-lib64" "--enable-lib32" ])
    else [
      "--enable-idl"
      "--enable-secure-api"
    ];

  enableParallelBuilding = true;

  buildInputs = lib.optional (!stdenv.targetPlatform.isCygwin) windows.mingw_w64_headers;
  dontStrip = true;
  hardeningDisable = [ "stackprotector" "fortify" ];

  meta = {
    platforms = lib.platforms.windows ++ lib.platforms.cygwin;
  };
}
