{
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  lib,
  writeShellScript,
  nix-update-script,
  nixfmt,
}:
let
  version = "1.3.3";
  pname = "WiseUnpacker";
in
buildDotnetModule rec {
  inherit version pname;

  src = fetchFromGitHub {
    owner = "mnadareski";
    repo = pname;
    rev = version;
    sha256 = "sha256-APbfo2D/p733AwNNByu5MvC9LA8WW4mAzq6t2w/YNrs=";
  };

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  dotnetFlags = [ "-p:TargetFramework=net8.0" ];

  # Rename to something sensible
  postFixup = ''
    mv "$out/bin/Test" "$out/bin/WiseUnpacker"
  '';

  nugetDeps = ./deps.nix;

  projectFile = "Test/Test.csproj";

  passthru.updateScript = writeShellScript "update-${pname}" ''
    set -euo pipefail
    ${lib.escapeShellArg (nix-update-script {})}
    $(nix-build -A "$UPDATE_NIX_ATTR_PATH".fetch-deps --no-out-link)
    ${lib.escapeShellArg nixfmt}/bin/nixfmt ${lib.escapeShellArg (toString nugetDeps)}
  '';

  meta = with lib; {
    homepage = "https://github.com/mnadareski/WiseUnpacker/";
    description = "C# Wise installer unpacker based on HWUN and E_WISE ";
    maintainers = [ maintainers.gigahawk ];
    license = licenses.mit;
  };
}
