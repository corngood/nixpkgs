{ stdenvNoCC
, lib
, fetchurl
, autoPatchelfHook
, zlib
, icu
, libunwind
, openssl
, unzip
, dotnetPackages
}:

{ pname
, version
, sha256
, url ? "https://www.nuget.org/api/v2/package/${pname}/${version}"
}: stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    name = "${pname}.${version}.nupkg";
    inherit url sha256;
  };

  buildInputs = [
    zlib
    icu
    libunwind
    openssl
  ];

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    dotnetPackages.Nuget
  ];

  buildCommand = ''
      HOME=$(pwd)/fake-home
      nuget add "$src" -source "$out"/share/nuget/packages -expand
  '';

  # unpackPhase = ''
  #   unzip $src
  #   chmod -R +rw .
  # '';

  # installPhase = ''
  #   dir=$out/share/nuget/packages/${lib.toLower pname}/${lib.toLower version}
  #   mkdir -p $dir
  #   cp -r . $dir
  #   echo {} > "$dir"/.nupkg.metadata
  # '';

  autoPatchelfIgnoreMissingDeps = [ "*" ];
}
