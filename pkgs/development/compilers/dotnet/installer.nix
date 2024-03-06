{
  stdenvNoCC,
  lib,
  callPackage,
  fetchFromGitHub,
  dotnet-sdk_8,
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
  linkFarm,
  fetchpatch
}: stdenvNoCC.mkDerivation (finalAttrs:
let sdk = dotnet-sdk_8;
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
    hash = "sha256-2fpsWrpSamwJrX4OOyO9Zdvqua1dP2J+W43JrQOG/t8=";
    leaveDotGit = true; # needed for GetCommitHash target
  };

  patches = [
    (fetchpatch {
      name = "ExtractArchiveToDirectory-open-.tar.gz-archives-read.patch";
      url = "https://github.com/corngood/installer/commit/9d0b6891ed97a9514bbd06a66d801b1b78415e62.patch";
      hash = "sha256-IqVY2IFt7S5e14IO98+Pmn/bdXmJUNtVDyLXmZuwcPQ=";
    })
  ];

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
    cp artifacts/packages/Release/Shipping/* $out
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
})
