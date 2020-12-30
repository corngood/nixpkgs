{ lib, stdenv
, fetchurl
, mono6
, msbuild
, dotnet-sdk
, makeWrapper
, dotnetPackages
}:

stdenv.mkDerivation rec {

  pname = "omnisharp-roslyn";
  version = "1.37.8";

  src = fetchurl {
    url = "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v${version}/omnisharp-mono.tar.gz";
    sha256 = "0kgv4l15rli9a7grmcsbv72csmxi7vqa7lrrr8bd4cq9ighh54q3";
  };

  nativeBuildInputs = [ makeWrapper dotnetPackages.Nuget ];

  preUnpack = ''
    mkdir src
    cd src
    sourceRoot=.
  '';

  installPhase = ''
    mkdir -p $out/bin
    cd ..
    cp -r src $out/
    rm -rf $out/src/.msbuild
    mkdir $out/src/.msbuild
    ln -s ${msbuild}/lib/mono/xbuild/* $out/src/.msbuild/
    rm $out/src/.msbuild/Current
    mkdir $out/src/.msbuild/Current
    ln -s ${msbuild}/lib/mono/xbuild/Current/* $out/src/.msbuild/Current/
    ln -s ${msbuild}/lib/mono/msbuild/Current/bin $out/src/.msbuild/Current/Bin

    makeWrapper ${mono6}/bin/mono $out/bin/omnisharp \
      --prefix PATH : ${dotnet-sdk}/bin \
      --add-flags "$out/src/OmniSharp.exe"
  '';

  meta = with lib; {
    description = "OmniSharp based on roslyn workspaces";
    homepage = "https://github.com/OmniSharp/omnisharp-roslyn";
    platforms = platforms.linux;
    license = licenses.mit;
    maintainers = with maintainers; [ tesq0 ericdallo ];
  };

}
