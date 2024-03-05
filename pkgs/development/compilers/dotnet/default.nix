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
    xmlstarlet
  }: stdenvNoCC.mkDerivation (finalAttrs:
  let
    sdk = dotnet_8_0_102.sdk_8_0;
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

      ./build.sh --build --configuration Release

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
