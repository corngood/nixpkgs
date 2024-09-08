{
  dotnetCorePackages,
  fetchFromGitHub,
  fetchNpmDeps,
  fetchzip,
  fontconfig,
  lib,
  libICE,
  libSM,
  libX11,
  libXcursor,
  libXext,
  libXi,
  libXrandr,
  liberation_ttf,
  makeFontsConf,
  nodejs,
  npmHooks,
  nugetPackages,
  prefetch-npm-deps,
  runCommand,
  stdenvNoCC,
  unicode-character-database,
  yq,
  mkNugetDeps,
}:

let allPackages =
stdenvNoCC.mkDerivation (
  finalAttrs:
  dotnetCorePackages.addNuGetDeps
    {
      nugetDeps = ./deps.nix;
      overrideFetchAttrs = a: {
        dontBuild = false;
        buildTarget = "Compile";
      };
    }
    rec {
      pname = "Avalonia";
      version = "11.0.11";

      src = fetchFromGitHub {
        owner = "AvaloniaUI";
        repo = "Avalonia";
        rev = version;
        fetchSubmodules = true;
        hash = "sha256-Du8DEsZKl7rnVH9YZKAWTCpEQ/5HrNlgacgK/46kx/o=";
      };

      patches = [
        # Fix failing tests that use unicode.org
        ./0001-use-files-for-unicode-character-database.patch
        # [ERR] Compile: [...]/Microsoft.NET.Sdk.targets(148,5): error MSB4018: The "GenerateDepsFile" task failed unexpectedly. [/build/source/src/tools/DevAnalyzers/DevAnalyzers.csproj]
        # [ERR] Compile: [...]/Microsoft.NET.Sdk.targets(148,5): error MSB4018: System.IO.IOException: The process cannot access the file '/build/source/src/tools/DevAnalyzers/bin/Release/netstandard2.0/DevAnalyzers.deps.json' because it is being used by another process. [/build/source/src/tools/DevAnalyzers/DevAnalyzers.csproj]
        ./0002-disable-parallel-compile.patch
        # ./0003-use-net6.0.patch
      ];

      # this needs to be match the version being patched above
      UNICODE_CHARACTER_DATABASE = fetchzip {
        url = "https://www.unicode.org/Public/15.0.0/ucd/UCD.zip";
        hash = "sha256-jj6bX46VcnH7vpc9GwM9gArG+hSPbOGL6E4SaVd0s60=";
        stripRoot = false;
      };

      postPatch =
        ''
          patchShebangs build.sh

          substituteInPlace src/Avalonia.X11/ICELib.cs \
            --replace-fail '"libICE.so.6"' '"${lib.getLib libICE}/lib/libICE.so.6"'
          substituteInPlace src/Avalonia.X11/SMLib.cs \
            --replace-fail '"libSM.so.6"' '"${lib.getLib libSM}/lib/libSM.so.6"'
          substituteInPlace src/Avalonia.X11/XLib.cs \
            --replace-fail '"libX11.so.6"' '"${lib.getLib libX11}/lib/libX11.so.6"' \
            --replace-fail '"libXrandr.so.2"' '"${lib.getLib libXrandr}/lib/libXrandr.so.2"' \
            --replace-fail '"libXext.so.6"' '"${lib.getLib libXext}/lib/libXext.so.6"' \
            --replace-fail '"libXi.so.6"' '"${lib.getLib libXi}/lib/libXi.so.6"' \
            --replace-fail '"libXcursor.so.1"' '"${lib.getLib libXcursor}/lib/libXcursor.so.1"'

          # from RestoreAdditionalProjectSources, which isn't supported by nuget-to-nix
          dotnet nuget add source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet8-transport/nuget/v3/index.json

          # Tricky way to run npmConfigHook multiple times (borrowed from pagefind)
          (
            local postPatchHooks=() # written to by npmConfigHook
            source ${npmHooks.npmConfigHook}/nix-support/setup-hook
        ''
        +
          # TODO: implement updateScript
          lib.concatMapStrings
            (
              { path, hash }:
              let
                deps = fetchNpmDeps {
                  src = "${src}/${path}";
                  inherit hash;
                };
              in
              ''
                npmRoot=${path} npmDeps="${deps}" npmConfigHook
                rm -rf "$TMPDIR/cache"
              ''
            )
            [
              {
                path = "src/Avalonia.DesignerSupport/Remote/HtmlTransport/webapp";
                hash = "sha256-gncHW5SMtAUMtvHGZ2nUc0KEjxX24DZkAnmeHgo1Roc=";
              }
              {
                path = "tests/Avalonia.DesignerSupport.Tests/Remote/HtmlTransport/webapp";
                hash = "sha256-MiznlOJ+hIO1cUswy9oGNHP6MWfx+FDLKVT8qcmg8vo=";
              }
              {
                path = "src/Browser/Avalonia.Browser/webapp";
                hash = "sha256-LTQzT4ycLyGQs9T0sa2k/0wfG1GWCdeH9Wx2KeecOyU=";
              }
            ]
        + ''
          )
          # Avalonia.Native is normally only packed on darwin.
          substituteInPlace src/Avalonia.Native/Avalonia.Native.csproj \
            --replace-fail \
              '<IsPackable>$(PackAvaloniaNative)</IsPackable>' \
              '<IsPackable>true</IsPackable>'
        '';

      makeCacheWritable = true;

      # CSC : error CS1566: Error reading resource 'pdbstr.exe' -- 'Could not find a part of the path '/build/.nuget-temp/packages/sourcelink/1.1.0/tools/pdbstr.exe'.' [/build/source/nukebuild/_build.csproj]
      linkNugetPackages = true;

      # [WRN] Could not inject value for Build.ApiCompatTool
      # System.Exception: Missing package reference/download.
      # Run one of the following commands:
      #  ---> System.ArgumentException: Could not find package 'Microsoft.DotNet.ApiCompat.Tool' using:
      #  - Project assets file '/build/source/nukebuild/obj/project.assets.json'
      #  - NuGet packages config '/build/source/nukebuild/_build.csproj'
      makeEmptyNupkgInPackages = true;

      buildInputs = [
        (
          with dotnetCorePackages;
          combinePackages [
            sdk_6_0
            sdk_7_0_1xx
          ]
        )
      ] ++ nugetPackages.findDependencies nugetPackages [ {
        packages = [
          # { id = "MicroCom.Runtime"; }
          # { id = "SkiaSharp"; }
        ];
      } ] ++ [
        (mkNugetDeps {
          name = "unsafe";
          nugetDeps = { fetchNuGet }: [
            (fetchNuGet { pname = "System.Runtime.CompilerServices.Unsafe"; version = "5.0.0"; hash = "sha256-neARSpLPUzPxEKhJRwoBzhPxK+cKIitLx7WBYncsYgo="; })
          ];
        })
      ];

      FONTCONFIG_FILE =
        let
          fc = makeFontsConf { fontDirectories = [ liberation_ttf ]; };
        in
        runCommand "fonts.conf" { } ''
          substitute ${fc} $out \
            --replace-fail "/etc/" "${fontconfig.out}/etc/"
        '';

      preConfigure = ''
        # closed source (telemetry?) https://github.com/AvaloniaUI/Avalonia/discussions/16878
        dotnet remove packages/Avalonia/Avalonia.csproj package Avalonia.BuildServices
      '';

      nativeBuildInputs = [ nodejs ];

      buildTarget = "Package";

      buildPhase = ''
        runHook preBuild
        # ValidateApiDiff requires a network connection
        ./build.sh --target $buildTarget --verbosity Verbose --skip ValidateApiDiff
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/share/nuget/source"
        cp artifacts/nuget/* "$out/share/nuget/source"
        runHook postInstall
      '';

      meta = {
        homepage = "https://avaloniaui.net/";
        license = [ lib.licenses.mit ];
        maintainers = with lib.maintainers; [
          corngood
        ];
        description = "A cross-platform UI framework for dotnet";
        sourceProvenance = with lib.sourceTypes; [
          fromSource
          binaryNativeCode # npm dependencies contain binaries
        ];
      };

      passthru = {
        nugetPackages = listToAttrs (map mkPackage
          (builtins.fromJSON (builtins.readFile ./nuget-packages.json)));
      };
    } finalAttrs);

  mkPackage =
    {
      id,
      version,
      hash,
      dependencies,
    }: nameValuePair id (stdenvNoCC.mkDerivation {
      pname = id;
      inherit version;
      src = allPackages;
      dontUnpack = true;
      passthru.nugetDependencies = dependencies;
      installPhase = ''
        runHook preInstall
        pkg="${toLower id}/${toLower version}"
        for dir in share/nuget/{packages,source}/"$pkg"; do
          mkdir -p "$out/$dir"
          cp -r "$src/$dir/." "$out/$dir"
        done
        runHook postInstall
      '';
    });

  inherit (lib)
    listToAttrs
    nameValuePair
    recurseIntoAttrs
    replaceStrings
    toLower;

root = mkPackage "avalonia" // {
  packages = recurseIntoAttrs (
    listToAttrs (
      map (n:
        nameValuePair (replaceStrings ["."] ["-"] n) (mkPackage ("avalonia." + n))) [
      "browser"
      "browser.blazor"
      "controls.colorpicker"
      "controls.datagrid"
      "controls.itemsrepeater"
      "desktop"
      "diagnostics"
      "direct2d1"
      "fonts.inter"
      "freedesktop"
      "headless"
      "headless.nunit"
      "headless.vnc"
      "headless.xunit"
      "linuxframebuffer"
      "markup.xaml.loader"
      "native"
      "reactiveui"
      "remote.protocol"
      "skia"
      "themes.fluent"
      "themes.simple"
      "win32"
      "x11"
    ]));
};

  in allPackages
