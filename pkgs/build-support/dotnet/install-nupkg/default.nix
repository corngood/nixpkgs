{ stdenv
, lib
, autoPatchelfHook
, zlib
, icu
, libunwind
, openssl
, unzip
}:

src: stdenv.mkDerivation {
  name = "${src.name}-installed";

  buildInputs = [
    zlib
    icu
    libunwind
    openssl
  ];
  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  inherit src;

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    dir=$out/share/nuget/packages/${package}/${version}
    mkdir -p $dir
    cp -r . $dir
  '';
}
