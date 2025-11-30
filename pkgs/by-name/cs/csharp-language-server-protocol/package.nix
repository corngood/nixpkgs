{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
}:
let
  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

in buildDotnetModule rec {
  inherit dotnet-sdk dotnet-runtime;

  pname = "csharp-language-server-protocol";
  version = "0.19.9";

  src = fetchFromGitHub {
    owner = "OmniSharp";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-NAzBm5ZaUtw+nJ4DhVofczM+k5p8Eil/lVNi+t2j4mU=";
  };

  patches = [
    ./0001-wip-fix-blocking-on-stdin.patch
  ];

  postPatch = ''
    rm global.json
  '';

  enableParallelBuilding = false;

  useAppHost = false;

  dotnetPackFlags = [ "-p:PackageIcon=" ];

  nugetDeps = ./deps.json;

  dontPublish = true;
  packNupkg = true;
}
