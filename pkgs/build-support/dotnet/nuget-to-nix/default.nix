{ lib
, runCommandLocal
, runtimeShell
, substituteAll
, nix
, coreutils
, jq
, yq
, curl
, gnugrep
, gawk
, dotnet-sdk
, python3
}:

runCommandLocal "nuget-to-nix" {
  nativeBuildInputs = [
    dotnet-sdk
  ];
  script = substituteAll {
    src = ./nuget-to-nix.py;
    pythonInterpreter = (python3.withPackages (ps: with ps; [ aiofiles aiohttp ])).interpreter;
    dotnet = dotnet-sdk;
    nix = nix;
  };

  meta.description = "Convert a nuget packages directory to a lockfile for buildDotnetModule";
} ''
  install -Dm755 $script $out/bin/nuget-to-nix
''
