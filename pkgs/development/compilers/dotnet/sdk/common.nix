{ stdenvNoCC
, lib
, writeText
, testers
, runCommand
}: type: args: stdenvNoCC.mkDerivation (finalAttrs: args // {
  doInstallCheck = true;

  postInstallCheck = ''
    $out/bin/dotnet --info >/dev/null
  '' + args.postInstallCheck or "";

} // lib.optionalAttrs (type == "sdk") {
  setupHook = writeText "dotnet-setup-hook" (''
    if [ ! -w "$HOME" ]; then
      export HOME=$(mktemp -d) # Dotnet expects a writable home directory for its configuration files
    fi

    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 # Dont try to expand NuGetFallbackFolder to disk
    export DOTNET_NOLOGO=1 # Disables the welcome message
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_WORKLOAD_INTEGRITY_CHECK=1 # Skip integrity check on first run, which fails due to read-only directory
  '' + args.setupHook or "");

  passthru = {
    tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
      };

      smoke-test = runCommand "dotnet-sdk-smoke-test" {
        nativeBuildInputs = [ finalAttrs.finalPackage ];
      } ''
        HOME=$(pwd)/fake-home
        dotnet new console --no-restore
        dotnet restore --source "$(mktemp -d)"
        dotnet build --no-restore
        output="$(dotnet run --no-build)"
        # yes, older SDKs omit the comma
        [[ "$output" =~ Hello,?\ World! ]] && touch "$out"
      '';
    } // args.passthru.tests or {};
  } // args.passthru or {};
})
