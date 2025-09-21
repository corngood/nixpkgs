{
  lib,
  stdenv,
  windows,
  autoreconfHook,
  mingw_w64_headers,
  crt ? stdenv.hostPlatform.libc,
  isW32api ? false,
}:

stdenv.mkDerivation {
  pname = if isW32api then "w32api" else "mingw-w64";
  inherit (mingw_w64_headers) version src meta;

  outputs = [
    "out"
    "dev"
  ];

  configureFlags =
    if isW32api then
      [
        (lib.enableFeature true "w32api")
      ]
    else
      [
        (lib.enableFeature true "idl")
        (lib.enableFeature true "secure-api")
        (lib.withFeatureAs true "default-msvcrt" crt)

        # Including other architectures causes errors with invalid asm
        (lib.enableFeature stdenv.hostPlatform.isi686 "lib32")
        (lib.enableFeature stdenv.hostPlatform.isx86_64 "lib64")
        (lib.enableFeature stdenv.hostPlatform.isAarch64 "libarm64")
      ];

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = lib.optional (!isW32api) mingw_w64_headers;
  hardeningDisable = [
    "stackprotector"
    "fortify"
  ];
}
