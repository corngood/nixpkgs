/*
How to combine packages for use in development:
dotnetCombined = with dotnetCorePackages; combinePackages [ sdk_6_0 aspnetcore_7_0 ];

Hashes and urls are retrieved from:
https://dotnet.microsoft.com/download/dotnet
*/
{ lib, config, callPackage, recurseIntoAttrs }:
let
  buildDotnet = attrs: callPackage (import ./build-dotnet.nix attrs) {};
  buildAttrs = {
    buildAspNetCore = attrs: buildDotnet (attrs // { type = "aspnetcore"; });
    buildNetRuntime = attrs: buildDotnet (attrs // { type = "runtime"; });
    buildNetSdk = attrs: buildDotnet (attrs // { type = "sdk"; });
  };

  ## Files in versions/ are generated automatically by update.sh ##
  dotnet_6_0 = import ./versions/6.0.nix buildAttrs;
  dotnet_7_0 = import ./versions/7.0.nix buildAttrs;
  dotnet_8_0 = import ./versions/8.0.nix buildAttrs;
  dotnet_8_0_102 = import ./versions/8.0.102.nix buildAttrs;

  runtimeIdentifierMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "osx-x64";
    "aarch64-darwin" = "osx-arm64";
    "x86_64-windows" = "win-x64";
    "i686-windows" = "win-x86";
  };

  # Convert a "stdenv.hostPlatform.system" to a dotnet RID
  systemToDotnetRid = system: runtimeIdentifierMap.${system} or (throw "unsupported platform ${system}");
in
{
  inherit systemToDotnetRid dotnet_8_0_102;

  combinePackages = attrs: callPackage (import ./combine-packages.nix attrs) {};

  installer = callPackage ({
    stdenvNoCC,
    fetchFromGitHub,
    writeShellScript,
    nix,
    jq,
    nuget-to-nix,
    cacert,
    mkNugetDeps,
    git,
    glibcLocales,
    xmlstarlet,
    fetchurl,
    linkFarm
  }: stdenvNoCC.mkDerivation (finalAttrs:
  let
    sdk = dotnet_8_0_102.sdk_8_0;
    bins = linkFarm "bins" (map ({name, hash}: {
      name = name;
      path = fetchurl {
        url = "https://dotnetcli.blob.core.windows.net/dotnet/${name}";
        inherit hash;
      };
    }) [
      {
        name = "Runtime/8.0.2-servicing.24067.11/dotnet-runtime-8.0.2-linux-x64.tar.gz";
        hash = "sha256-5Oepaqyb0Uec9yjTCWXQ357Aoi/DXTRTjnuqz7WgdJE=";
      }
      {
        name = "Sdk/8.0.200-rtm.24069.18/dotnet-toolset-internal-8.0.200-rtm.24069.18.zip";
        hash = "sha256-sa+KmWOhPa6Mppp6mzJ3mp9E+tvnwSDJXHfE1Lmonww=";
      }
      {
        name = "aspnetcore/Runtime/8.0.2-servicing.24068.4/aspnetcore-runtime-8.0.2-linux-x64.tar.gz";
        hash = "sha256-l0ioxEsgIZt1Kbjd6MF6oH362wIGYJ6mznMpJpN5oSE=";
      }
      {
        name = "aspnetcore/Runtime/8.0.2-servicing.24068.4/aspnetcore_base_runtime.version";
        hash = "sha256-/TCSlKch6sJ3iTU6nyMGAGEhmnmn0Gukf60jpvWqARU=";
      }
    ]);
  in rec {
    name = "installer";
    version = "8.0.201";

    DOTNET_INSTALL_DIR = sdk;

    # https://github.com/NixOS/nixpkgs/issues/38991
    # bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
    LOCALE_ARCHIVE = lib.optionalString stdenvNoCC.isLinux
      "${glibcLocales}/lib/locale/locale-archive";

    src = fetchFromGitHub {
      owner = "dotnet";
      repo = name;
      rev = "v${version}";
      hash = "sha256-OHnNokpoy91DWBKKWpMoFKMHb7OwW/t0goqXYaZUSoU=";
    };

    depsSource = mkNugetDeps {
      name = "${name}-deps";
      sourceFile = ./${name}/deps.nix;
    };

    nativeBuildInputs = [
      jq
      nuget-to-nix
      cacert
      git
      (callPackage ./patch-nupkgs.nix {})
      xmlstarlet
    ];

    buildInputs = [
      sdk
    ];

    postPatch = ''
      # set the sdk version in global.json to match the bootstrap sdk
      jq '.tools.dotnet=$dotnet | del(.tools.runtimes)' \
        global.json \
        --arg dotnet "$(dotnet --version)" \
        > global.json~
      mv global.json{~,}

      substituteInPlace \
        run-build.sh \
        --replace-fail '--build --restore' ""

      patchShebangs $(find -name \*.sh -type f -executable)

      xmlstarlet ed \
        --inplace \
        -s //Project -t elem -n Import \
        -i \$prev -t attr -n Project -v "${./patch-restored-packages.proj}" \
        Directory.Build.targets
    '';

    configurePhase = ''
      runHook preConfigure

      if [[ -v depsSource ]]; then
        rm NuGet.config
        dotnet new nugetconfig
        dotnet nuget disable source nuget
        [[ ! -v depsSource ]] || dotnet nuget add source -n deps "$depsSource"
      fi

      dotnet nuget add source -n sdk "${sdk.packages}"

      ./build.sh --restore

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      ./build.sh --build --configuration Release -p:PublicBaseURL=file://${bins}/

      runHook postBuild
    '';

    installPhase = ''
      mkdir $out
      cp artifacts/Release/Shipping/* $out
    '';

    passthru = {
      fetch-deps =
        let
          pkg = finalAttrs.finalPackage.overrideAttrs (old: {
            depsSource = null;
          });
          drv = builtins.unsafeDiscardOutputDependency pkg.drvPath;
        in
          writeShellScript "fetch-dotnet-sdk-deps" ''
            ${nix}/bin/nix-shell --pure --run 'source /dev/stdin' "${drv}" << 'EOF'
            set -e

            tmp=$(mktemp -d -p $PWD)
            # trap 'rm -fr "$tmp"' EXIT

            HOME=$tmp/.home
            cd "$tmp"

            # TODO: make buildPhase optional
            phases="''${prePhases[*]:-} unpackPhase patchPhase ''${preConfigurePhases[*]:-} configurePhase buildPhase" \
              genericBuild

            nuget-to-nix .nuget/packages > "${toString depsSource.sourceFile}"

            EOF
          '';
      };
  })) {};

  dotnet_8 = recurseIntoAttrs (callPackage ./8 { bootstrapSdk = dotnet_8_0_102.sdk_8_0; });
} // lib.optionalAttrs config.allowAliases {
  # EOL
  sdk_2_1 = throw "Dotnet SDK 2.1 is EOL, please use 6.0 (LTS) or 7.0 (Current)";
  sdk_2_2 = throw "Dotnet SDK 2.2 is EOL, please use 6.0 (LTS) or 7.0 (Current)";
  sdk_3_0 = throw "Dotnet SDK 3.0 is EOL, please use 6.0 (LTS) or 7.0 (Current)";
  sdk_3_1 = throw "Dotnet SDK 3.1 is EOL, please use 6.0 (LTS) or 7.0 (Current)";
  sdk_5_0 = throw "Dotnet SDK 5.0 is EOL, please use 6.0 (LTS) or 7.0 (Current)";
} // dotnet_6_0 // dotnet_7_0 // dotnet_8_0
