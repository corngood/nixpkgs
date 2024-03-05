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
    cacert
  }: stdenvNoCC.mkDerivation (finalAttrs:
  let
    depsFile = ./${finalAttrs.name}/deps.nix;
  in rec {
    name = "installer";
    version = "8.0.201";

    preHook = ''
      export DOTNET_INSTALL_DIR=${dotnet_8_0_102.sdk_8_0}
    '';

    src = fetchFromGitHub {
      owner = "dotnet";
      repo = name;
      rev = "v${version}";
      hash = "sha256-OHnNokpoy91DWBKKWpMoFKMHb7OwW/t0goqXYaZUSoU=";
    };

    nativeBuildInputs = [
      jq
      nuget-to-nix
      cacert
    ];

    buildInputs = [
      dotnet_8_0_102.sdk_8_0
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
    '';

    configurePhase = ''
      runHook preConfigure
      ./build.sh --restore
      runHook postConfigure
    '';

    passthru = {
      fetch-deps =
        let
          drv = builtins.unsafeDiscardOutputDependency finalAttrs.finalPackage.drvPath;
        in
          writeShellScript "fetch-dotnet-sdk-deps" ''
            ${nix}/bin/nix-shell --pure --run 'source /dev/stdin' "${drv}" << 'EOF'
            set -e

            tmp=$(mktemp -d -p $PWD)
            # trap 'rm -fr "$tmp"' EXIT

            HOME=$tmp/.home
            cd "$tmp"

            export NUGET_PACKAGES=$tmp/.nupkgs

            phases="''${prePhases[*]:-} unpackPhase patchPhase ''${preConfigurePhases[*]:-} configurePhase" \
              genericBuild

            nuget-to-nix $NUGET_PACKAGES > "${toString depsFile}"

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
