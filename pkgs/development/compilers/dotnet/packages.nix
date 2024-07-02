{ stdenv
, callPackage
, vmr
}:

let
  mkCommon = callPackage ./common.nix {};
  inherit (vmr) targetRid releaseManifest;

in {
  inherit vmr;
  sdk = mkCommon "sdk" rec {
    pname = "dotnet-sdk";
    version = releaseManifest.sdkVersion;

    src = vmr;
    dontUnpack = true;

    outputs = [ "out" "packages" "artifacts" ];

    installPhase = ''
      runHook preInstall

      cp -r "$src"/dotnet-sdk-${version}-${targetRid} "$out"
      chmod +w "$out"
      mkdir "$out"/bin
      ln -s "$out"/dotnet "$out"/bin/dotnet

      mkdir "$packages"/share/nuget/packages
      # this roughly corresponds to the {sdk,aspnetcore}_packages in ../update.sh
      mv "$src"/share/nuget/packages/*microsoft.{net.illink.tasks,netcore,dotnet,aspnetcore}* \
        "$packages"/share/nuget/packages/

      mkdir -p "$artifacts"/share/nuget/packags
      mv -r "$src"/share/nuget/packages/* "$artifacts"/share/nuget/packages/

      runHook postInstall
    '';

    passthru = {
      inherit (vmr) icu targetRid;
      # ilcompiler is currently broken: https://github.com/dotnet/source-build/issues/1215
      hasILCompiler = false;
    };

    meta = vmr.meta // {
      mainProgram = "dotnet";
    };
  };

  runtime = mkCommon "runtime" rec {
    pname = "dotnet-runtime";
    version = releaseManifest.runtimeVersion;

    src = vmr;
    dontUnpack = true;

    outputs = [ "out" ];

    installPhase = ''
      runHook preInstall

      cp -r "$src/dotnet-runtime-${version}-${targetRid}" "$out"
      chmod +w "$out"
      mkdir "$out"/bin
      ln -s "$out"/dotnet "$out"/bin/dotnet

      runHook postInstall
    '';

    meta = vmr.meta // {
      mainProgram = "dotnet";
    };
  };

  aspnetcore = mkCommon "aspnetcore" rec {
    pname = "dotnet-aspnetcore-runtime";
    version = releaseManifest.aspNetCoreVersion or releaseManifest.runtimeVersion;

    src = vmr;
    dontUnpack = true;

    outputs = [ "out" ];

    installPhase = ''
      runHook preInstall

      cp -r "$src/dotnet-runtime-${releaseManifest.runtimeVersion}-${targetRid}" "$out"
      chmod +w "$out"
      mkdir "$out"/bin
      ln -s "$out"/dotnet "$out"/bin/dotnet

      chmod +w "$out"/shared
      cp -Tr "$src/aspnetcore-runtime-${version}-${targetRid}" "$out"

      runHook postInstall
    '';

    meta = vmr.meta // {
      mainProgram = "dotnet";
    };
  };
}
