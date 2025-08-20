{
  dotnetCorePackages,
  lib,
  stdenvNoCC,
  writeText,
}:
let
  host-sdk = dotnetCorePackages.sdk_10_0;
  target-sdk = dotnetCorePackages.sdk_9_0;

  runtimeVersion = target-sdk.runtime.version;
  targetFramework = "net${lib.versions.majorMinor target-sdk.version}";

  targets = writeText "Directory.Build.targets" ''
    <Project>
      <ItemGroup>
        <KnownFrameworkReference Update="@(KnownFrameworkReference)">
          <LatestRuntimeFrameworkVersion Condition="'%(TargetFramework)' == '${targetFramework}'">${runtimeVersion}</LatestRuntimeFrameworkVersion>
          <TargetingPackVersion Condition="'%(TargetFramework)' == '${targetFramework}'">${runtimeVersion}</TargetingPackVersion>
        </KnownFrameworkReference>
        <KnownAppHostPack Update="@(KnownAppHostPack)">
          <AppHostPackVersion Condition="'%(TargetFramework)' == '${targetFramework}'">${runtimeVersion}</AppHostPackVersion>
        </KnownAppHostPack>
      </ItemGroup>
    </Project>
  '';

  src = stdenvNoCC.mkDerivation {
    name = "target-framework-src";

    nativeBuildInputs = [
      target-sdk
    ];

    unpackPhase = ''
      mkdir test
      cd test
      dotnet new console
      cp ${lib.escapeShellArg targets} Directory.Build.targets
      cd ..
    '';

    installPhase = ''
      mv test "$out"
    '';
  };

  dotnet-sdk =
    with dotnetCorePackages;
    host-sdk
    // {
      inherit (target-sdk)
        packages
        targetPackages
        ;
    };

in
stdenvNoCC.mkDerivation {
  name = "target-framework";

  inherit src;

  nativeBuildInputs = [
    dotnet-sdk
  ];

  buildInputs = dotnet-sdk.packages;

  buildPhase = ''
    dotnet build
  '';

  installPhase = ''
    dotnet publish -o "$out"/lib
  '';
}
