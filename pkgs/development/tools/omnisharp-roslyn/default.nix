{ buildDotnetModule
, dotnetCorePackages
, dotnet-sdk
, dotnet-runtime
, fetchFromGitHub
, icu
, lib
, patchelf
, stdenv
, runCommand
, expect
}:
let finalPackage = buildDotnetModule rec {
  pname = "omnisharp-roslyn";
  version = "1.39.2";

  src = fetchFromGitHub {
    owner = "OmniSharp";
    repo = pname;
    rev = "v${version}";
    sha256 = "/MxBdMjPpq3Gwhi/93+JCAI+BuiiWu0n9QThQi+s/kE=";
  };

  projectFile = "src/OmniSharp.Stdio.Driver/OmniSharp.Stdio.Driver.csproj";
  nugetDeps = ./deps.nix;

  nativeBuildInputs = [
    patchelf
  ];

  buildInputs = with dotnetCorePackages; [
    newtonsoft-json_11
    newtonsoft-json_13
  ];

  dotnetInstallFlags = [ "--framework net6.0" ];
  dotnetBuildFlags = [ "--framework net6.0" "--no-self-contained" ];
  dotnetFlags = [
    # These flags are set by the cake build.
    "-property:PackageVersion=${version}"
    "-property:AssemblyVersion=${version}.0"
    "-property:FileVersion=${version}.0"
    "-property:InformationalVersion=${version}"
    "-property:RuntimeFrameworkVersion=${dotnet-runtime.version}"
    "-property:RollForward=LatestMajor"
    # allow unsigned dependencies
    "-property:DisabledWarnings=S8002"
  ];

  postPatch = ''
    # Relax the version requirement
    substituteInPlace global.json \
      --replace '7.0.100-rc.1.22431.12' '${dotnet-sdk.version}'
    substituteInPlace build/Settings.props \
      --replace '</NoWarn>' ';CS8002</NoWarn>'
  '';

  dontDotnetFixup = true; # we'll fix it ourselves
  postFixup = ''
    # Now create a wrapper without DOTNET_ROOT
    # we explicitly don't set DOTNET_ROOT as it should get the one from PATH
    # as you can use any .NET SDK higher than 6 to run OmniSharp and you most
    # likely will NOT want the .NET 6 runtime running it (as it'll use that to
    # detect the SDKs for its own use, so it's better to let it find it in PATH).
    makeWrapper $out/lib/omnisharp-roslyn/OmniSharp $out/bin/OmniSharp \
      --prefix LD_LIBRARY_PATH : ${dotnet-sdk.icu}/lib \
      --set-default DOTNET_ROOT ${dotnet-sdk}
  '';

  passthru.tests = {
    no-sdk = runCommand "no-sdk" { nativeBuildInputs = [ finalPackage expect ]; meta.timeout = 60; } ''
      HOME=$TMPDIR
      expect <<"EOF"
        spawn OmniSharp
        expect_before timeout {
          send_error "timeout!\n"
          exit 1
        }
        expect "\"ERROR\",\"Name\":\"OmniSharp.MSBuild.Discovery.Providers.SdkInstanceProvider\""
        expect eof
        catch wait result
        if { [lindex $result 3] == 0 } {
          exit 1
        }
      EOF
      touch $out
    '';

    with-sdk = runCommand "with-sdk" { nativeBuildInputs = [ finalPackage dotnet-sdk expect ]; meta.timeout = 60; } ''
      HOME=$TMPDIR
      expect <<"EOF"
        spawn OmniSharp
        expect_before timeout {
          send_error "timeout!\n"
          exit 1
        }
        expect "{\"Event\":\"started\","
        send \x03
        expect eof
        catch wait result
        exit [lindex $result 3]
      EOF
      touch $out
    '';
  };

  meta = with lib; {
    description = "OmniSharp based on roslyn workspaces";
    homepage = "https://github.com/OmniSharp/omnisharp-roslyn";
    sourceProvenance = with sourceTypes; [
      fromSource
      binaryNativeCode # dependencies
    ];
    license = licenses.mit;
    maintainers = with maintainers; [ tesq0 ericdallo corngood mdarocha ];
    mainProgram = "OmniSharp";
  };
}; in finalPackage
