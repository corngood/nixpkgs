{ clangStdenv
, stdenvNoCC
, lib
, fetchFromGitHub
, dotnetCorePackages
, jq
, yq
, curl
, git
, cmake
, pkg-config
, llvm
, zlib
, icu
, lttng-ust_2_12
, libkrb5
, glibcLocales
, ensureNewerSourcesForZipFilesHook
, darwin
, xcbuild
, swift
, openssl
, getconf
, makeWrapper

, dotnetSdk
, releaseManifest
, hash
}:

let
  inherit (clangStdenv)
    isLinux
    isDarwin
    buildPlatform
    targetPlatform;
  inherit (darwin) cctools;

  manifestJson = lib.importJSON releaseManifest;

  buildRid = dotnetCorePackages.systemToDotnetRid buildPlatform.system;
  targetRid = dotnetCorePackages.systemToDotnetRid targetPlatform.system;
  targetArch = lib.elemAt (lib.splitString "-" targetRid) 1;

  sigtool = darwin.sigtool.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "corngood";
      repo = "sigtool";
      rev = "new-commands";
      sha256 = "sha256-EVM5ZG3sAHrIXuWrnqA9/4pDkJOpWCeBUl5fh0mkK4k=";
    };

    nativeBuildInputs = old.nativeBuildInputs or [] ++ [
      makeWrapper
    ];

    postInstall = old.postInstall or "" + ''
      wrapProgram $out/bin/codesign \
        --set-default CODESIGN_ALLOCATE \
          "${cctools}/bin/${cctools.targetPrefix}codesign_allocate"
    '';
  });

  # we need dwarfdump from cctools, but can't have e.g. 'ar' overriding stdenv
  dwarfdump = stdenvNoCC.mkDerivation {
    name = "dwarfdump-wrapper";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/bin"
      ln -s "${cctools}/bin/dwarfdump" "$out/bin"
    '';
  };

  _icu = if isDarwin then darwin.ICU else icu;

in clangStdenv.mkDerivation rec {
  pname = "dotnet-sdk-vmr";
  version = manifestJson.release;

  src = fetchFromGitHub {
    owner = "dotnet";
    repo = "dotnet";
    rev = "refs/tags/v${version}";
    inherit hash;
  };

  sbArtifacts = dotnetSdk.artifacts;

  nativeBuildInputs = [
    ensureNewerSourcesForZipFilesHook
    jq
    yq
    curl.bin
    git
    cmake
    pkg-config
  ]
  ++ lib.optionals isDarwin [
    getconf
  ];

  buildInputs = [
    # this gets copied into the tree, but we still want the hooks to run
    dotnetSdk
    # the propagated build inputs in llvm.dev break swift compilation
    llvm.out
    zlib
    _icu
    openssl
  ]
  ++ lib.optionals isLinux [
    libkrb5
    lttng-ust_2_12
  ]
  ++ lib.optionals isDarwin (with darwin.apple_sdk_11_0.frameworks; [
    xcbuild.xcrun
    swift
    (libkrb5.overrideAttrs (old: {
      # the propagated build inputs break swift compilation
      buildInputs = old.buildInputs ++ old.propagatedBuildInputs;
      propagatedBuildInputs = [];
    }))
    dwarfdump
    sigtool
    Foundation
    CoreFoundation
    CryptoKit
    System
  ]);

  patches = [
    ./fix-aspnetcore-portable-build.patch
    ./fix-tmp-path.patch
  ]
  ++ lib.optionals isDarwin [
    ./stop-passing-bare-sdk-arg-to-swiftc.patch
    ./disable-installer-in-runtime.patch
  ];

  postPatch = ''
    # set the sdk version in global.json to match the bootstrap sdk
    jq '(.tools.dotnet=$dotnet)' global.json --arg dotnet "$(${dotnetSdk}/bin/dotnet --version)" > global.json~
    mv global.json{~,}

    # set the url used by prep.sh to point to the nix store
    xq -x \
      '.Project.PropertyGroup |= map(if has("PrivateSourceBuiltArtifactsUrl") then .PrivateSourceBuiltArtifactsUrl=$url else . end)' \
      eng/Versions.props \
      --arg url "file://$(echo "${dotnetSdk.artifacts}"/*.tar.gz)" \
      > eng/Versions.props~
    mv eng/Versions.props{~,}

    patchShebangs $(find -name \*.sh -type f -executable)

    # I'm not sure why this is required, but these files seem to use the wrong
    # property name.
    sed -i 's:\bVersionBase\b:VersionPrefix:g' \
      src/xliff-tasks/eng/Versions.props
  ''
  + lib.optionalString isLinux ''
    substituteInPlace \
      src/runtime/src/native/libs/System.Net.Security.Native/pal_gssapi.c \
      --replace '"libgssapi_krb5.so.2"' '"${libkrb5}/lib/libgssapi_krb5.so.2"'

    substituteInPlace \
      src/runtime/src/native/libs/System.Globalization.Native/pal_icushim.c \
      --replace '"libicui18n.so"' '"${icu}/lib/libicui18n.so"' \
      --replace '"libicuuc.so"' '"${icu}/lib/libicuuc.so"' \
      --replace 'libicuucName[64]' 'libicuucName[256]' \
      --replace 'libicui18nName[64]' 'libicui18nName[256]'
  ''
  + lib.optionalString isDarwin ''
    substituteInPlace \
      src/runtime/src/mono/CMakeLists.txt \
      src/runtime/src/native/libs/System.Globalization.Native/CMakeLists.txt \
      --replace '/usr/lib/libicucore.dylib' '${darwin.ICU}/lib/libicucore.dylib'

    substituteInPlace \
      src/runtime/src/installer/managed/Microsoft.NET.HostModel/HostModelUtils.cs \
      src/sdk/src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.targets \
      --replace '/usr/bin/codesign' '${sigtool}/bin/codesign'
  '';

  prepFlags = [];

  configurePhase = ''
    runHook preConfigure

    # The build process tries to overwrite some things in the sdk (e.g.
    # SourceBuild.MSBuildSdkResolver.dll), so it needs to be mutable.
    cp -Tr ${dotnetSdk} .dotnet
    chmod -R +w .dotnet

    HOME=$(pwd)/fake-home \
      ./prep.sh $prepFlags

    runHook postConfigure
  '';

  dontUseCmakeConfigure = true;

  # https://github.com/NixOS/nixpkgs/issues/38991
  # bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
  LOCALE_ARCHIVE = lib.optionalString isLinux
      "${glibcLocales}/lib/locale/locale-archive";

  buildFlags = [
    "--clean-while-building"
    "--release-manifest" releaseManifest
    "--"
    "-p:PortableBuild=true"
  ] ++ lib.optional (targetRid != buildRid) "-p:TargetRid=${targetRid}";

  buildPhase = ''
    runHook preBuild

    # If version is set, it overrides the version of certain packages, such as
    # newtonsoft-json, which breaks things that depend on it.

    # CLR_CC/CXX need to be set to stop the build system from using clang-11,
    # which is unwrapped

    # icu needs to be in the LD path so the newly built libraries will work
    # before being patched in fixup

    # Nuget needs a writable home dir.

    version= \
    CLR_CC=$(command -v clang) \
    CLR_CXX=$(command -v clang++) \
    HOME=$(pwd)/fake-home \
      ./build.sh $buildFlags

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir "$out"

    pushd "artifacts/${targetArch}/Release"
    for archive in *.tar.gz; do
      target=$out/''${archive%.tar.gz}
      mkdir "$target"
      tar -C "$target" -xzf "$PWD/$archive"
    done
    popd

    runHook postInstall
  '';

  passthru = {
    inherit manifestJson buildRid targetRid;
    icu = _icu;
    # TODO
    # updateScript = ./update.sh;
  };

  meta = with lib; {
    description = "Core functionality needed to create .NET Core projects, that is shared between Visual Studio and CLI";
    homepage = "https://dotnet.github.io/";
    license = licenses.mit;
    maintainers = with maintainers; [ corngood ];
    mainProgram = "dotnet";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
