{
  alsa-lib,
  autoPatchelfHook,
  buildPackages,
  dbus,
  dotnetCorePackages,
  embree,
  enet,
  fetchFromGitHub,
  fontconfig,
  freetype,
  glib,
  glslang,
  graphite2,
  harfbuzz,
  hash,
  icu,
  installShellFiles,
  lib,
  libdecor,
  libGL,
  libpulseaudio,
  libtheora,
  libwebp,
  libX11,
  libXcursor,
  libXext,
  libXi,
  libXinerama,
  libxkbcommon,
  libXrandr,
  libXrender,
  makeWrapper,
  mbedtls,
  miniupnpc,
  openxr-loader,
  pcre2,
  pkg-config,
  recastnavigation,
  runCommand,
  scons,
  speechd-minimal,
  stdenv,
  stdenvNoCC,
  testers,
  udev,
  version,
  vulkan-loader,
  wayland,
  wayland-scanner,
  withAlsa ? true,
  withDbus ? true,
  withFontconfig ? true,
  withMono ? false,
  nugetDeps ? null,
  withPlatform ? "linuxbsd",
  withPrecision ? "single",
  withPulseaudio ? true,
  withSpeechd ? true,
  withTarget ? "editor",
  withTouch ? true,
  withUdev ? true,
  # Wayland in Godot requires X11 until upstream fix is merged
  # https://github.com/godotengine/godot/pull/73504
  withWayland ? true,
  withX11 ? true,
  wslay,
  zstd,
}:
assert lib.asserts.assertOneOf "withPrecision" withPrecision [
  "single"
  "double"
];
let
  mkSconsFlagsFromAttrSet = lib.mapAttrsToList (
    k: v: if builtins.isString v then "${k}=${v}" else "${k}=${builtins.toJSON v}"
  );

  suffix = if withMono then "-mono" else "";

  arch = stdenv.hostPlatform.linuxArch;

  dotnet-sdk = dotnetCorePackages.sdk_8_0-source;

  attrs = finalAttrs: rec {
    pname = "godot4${suffix}";
    inherit version;

    src = fetchFromGitHub {
      owner = "godotengine";
      repo = "godot";
      tag = version;
      inherit hash;
      # Required for the commit hash to be included in the version number.
      #
      # `methods.py` reads the commit hash from `.git/HEAD` and manually follows
      # refs.
      #
      # See also 'hash' in
      # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
      leaveDotGit = true;
      # Only keep HEAD, because leaveDotGit is non-deterministic:
      # https://github.com/NixOS/nixpkgs/issues/8567
      postFetch = ''
        hash=$(git -C "$out" rev-parse HEAD)
        rm -r "$out"/.git
        mkdir "$out"/.git
        echo "$hash" > "$out"/.git/HEAD
      '';
    };

    outputs = [
      "out"
      "man"
    ];
    separateDebugInfo = true;

    # Set the build name which is part of the version. In official downloads, this
    # is set to 'official'. When not specified explicitly, it is set to
    # 'custom_build'. Other platforms packaging Godot (Gentoo, Arch, Flatpack
    # etc.) usually set this to their name as well.
    #
    # See also 'methods.py' in the Godot repo and 'build' in
    # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
    BUILD_NAME = "nixpkgs";

    preConfigure = lib.optionalString withMono ''
      # TODO: avoid pulling in dependencies of windows-only project
      dotnet sln modules/mono/editor/GodotTools/GodotTools.sln \
        remove modules/mono/editor/GodotTools/GodotTools.OpenVisualStudio/GodotTools.OpenVisualStudio.csproj

      dotnet restore modules/mono/glue/GodotSharp/GodotSharp.sln
      dotnet restore modules/mono/editor/GodotTools/GodotTools.sln
      dotnet restore modules/mono/editor/Godot.NET.Sdk/Godot.NET.Sdk.sln
    '';

    # From: https://github.com/godotengine/godot/blob/4.2.2-stable/SConstruct
    sconsFlags = mkSconsFlagsFromAttrSet {
      # Options from 'SConstruct'
      precision = withPrecision; # Floating-point precision level
      production = true; # Set defaults to build Godot for use in production
      platform = withPlatform;
      target = withTarget;
      debug_symbols = true;

      # Options from 'platform/linuxbsd/detect.py'
      alsa = withAlsa;
      dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
      fontconfig = withFontconfig; # Use fontconfig for system fonts support
      pulseaudio = withPulseaudio; # Use PulseAudio
      speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
      touch = withTouch; # Enable touch events
      udev = withUdev; # Use udev for gamepad connection callbacks
      wayland = withWayland; # Compile with Wayland support
      x11 = withX11; # Compile with X11 support

      module_mono_enabled = withMono;

      linkflags = "-Wl,--build-id";

      # libraries that aren't available in nixpkgs
      builtin_msdfgen = true;
      builtin_rvo2_2d = true;
      builtin_rvo2_3d = true;
      builtin_xatlas = true;

      # using system clipper2 is currently not implemented
      builtin_clipper2 = true;

      use_sowrap = false;
    };

    enableParallelBuilding = true;

    strictDeps = true;

    patches = [
      # this stops scons from hiding e.g. NIX_CFLAGS_COMPILE
      ./SConstruct-inherit-external-environment.patch
      ./Linux-fix-missing-library-with-builtin_glslang-false.patch
      ./SConstruct-disable-builtin_-by-default.patch
    ];

    postPatch = ''
      # disable all builtin libraries by default
      perl -pi -e '{ $r |= s:(opts.Add\(BoolVariable\("builtin_.*, )True(\)\)):\1False\2: } END { exit ($r != 1) }' SConstruct

      substituteInPlace platform/linuxbsd/detect.py \
        --replace-fail /usr/include/recastnavigation ${lib.escapeShellArg (lib.getDev recastnavigation)}/include/recastnavigation

      substituteInPlace thirdparty/glad/egl.c \
        --replace-fail \
          'static const char *NAMES[] = {"libEGL.so.1", "libEGL.so"}' \
          'static const char *NAMES[] = {"${lib.getLib libGL}/lib/libEGL.so"}'

      substituteInPlace thirdparty/glad/gl.c \
        --replace-fail \
          'static const char *NAMES[] = {"libGLESv2.so.2", "libGLESv2.so"}' \
          'static const char *NAMES[] = {"${lib.getLib libGL}/lib/libGLESv2.so"}' \

      substituteInPlace thirdparty/glad/gl{,x}.c \
        --replace-fail \
          '"libGL.so.1"' \
          '"${lib.getLib libGL}/lib/libGL.so"'

      substituteInPlace thirdparty/volk/volk.c \
        --replace-fail \
          'dlopen("libvulkan.so.1"' \
          'dlopen("${lib.getLib vulkan-loader}/lib/libvulkan.so"'
    '';

    depsBuildBuild = lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
      buildPackages.stdenv.cc
      pkg-config
    ];

    buildInputs =
      [
        embree
        enet
        freetype
        glslang
        graphite2
        (harfbuzz.override { withIcu = true; })
        icu
        libtheora
        libwebp
        mbedtls
        miniupnpc
        openxr-loader
        pcre2
        recastnavigation
        wslay
        zstd
      ]
      ++ lib.optionals withMono dotnet-sdk.packages
      ++ lib.optional withAlsa alsa-lib
      ++ lib.optional (withX11 || withWayland) libxkbcommon
      ++ lib.optionals withX11 [
        libX11
        libXcursor
        libXext
        libXi
        libXinerama
        libXrandr
        libXrender
      ]
      ++ lib.optionals withWayland [
        # libdecor
        wayland
      ]
      ++ lib.optionals withDbus [
        dbus
      ]
      ++ lib.optionals withFontconfig [
        fontconfig
      ]
      ++ lib.optional withPulseaudio libpulseaudio
      ++ lib.optionals withSpeechd [
        speechd-minimal
        glib
      ]
      ++ lib.optional withUdev udev;

    nativeBuildInputs =
      [
        installShellFiles
        pkg-config
        scons
      ]
      ++ lib.optionals withWayland [ wayland-scanner ]
      ++ lib.optionals withMono [
        dotnet-sdk
        makeWrapper
      ];

    postBuild = lib.optionalString withMono ''
      echo "Generating Glue"
      if [[ ${withPrecision} == *double* ]]; then
          bin/godot.${withPlatform}.${withTarget}.${withPrecision}.${arch}.mono --headless --generate-mono-glue modules/mono/glue
      else
          bin/godot.${withPlatform}.${withTarget}.${arch}.mono --headless --generate-mono-glue modules/mono/glue
      fi
      echo "Building C#/.NET Assemblies"
      python modules/mono/build_scripts/build_assemblies.py --godot-output-dir bin --precision=${withPrecision}
    '';

    installPhase =
      ''
        runHook preInstall

        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot4${suffix}

        installManPage misc/dist/linux/godot.6

        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/org.godotengine.Godot4${suffix}.desktop"
        substituteInPlace "$out/share/applications/org.godotengine.Godot4${suffix}.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot4${suffix}" \
          --replace "Godot Engine" "Godot Engine 4"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      ''
      + lib.optionalString withMono ''
        cp -r bin/GodotSharp/ $out/bin/
        wrapProgram $out/bin/godot4${suffix} \
          --set DOTNET_ROOT ${dotnet-sdk} \
          --prefix PATH : "${
            lib.makeBinPath [
              dotnet-sdk
            ]
          }"
      ''
      + ''
        ln -s godot4${suffix} "$out"/bin/godot
        runHook postInstall
      '';

    passthru = {
      tests =
        let
          pkg = finalAttrs.finalPackage;
          dottedVersion = lib.replaceStrings [ "-" ] [ "." ] version;
          exportedProject = stdenvNoCC.mkDerivation {
            name = "${pkg.name}-project-export";

            nativeBuildInputs = [
              pkg
              autoPatchelfHook
            ];

            runtimeDependencies = map lib.getLib [
              alsa-lib
              libpulseaudio
              libX11
              libXcursor
              libXext
              libXi
              libXrandr
              udev
              vulkan-loader
            ];

            unpackPhase = ''
              runHook preUnpack

              mkdir test
              cd test
              touch project.godot

              cat >create-scene.gd <<'EOF'
              extends SceneTree

              func _initialize():
                var node = Node.new()
                var script = ResourceLoader.load("res://test.gd")
                print(script)
                node.set_script(script)
                var scene = PackedScene.new()
                var scenePath = "res://test.tscn"
                scene.pack(node)
                var x = ResourceSaver.save(scene, scenePath)
                ProjectSettings["application/run/main_scene"] = scenePath
                ProjectSettings.save()
                node.free()
                quit()
              EOF

              cat >test.gd <<'EOF'
              extends Node
              func _ready():
                print("Hello, World!")
                get_tree().quit()
              EOF

              cat >export_presets.cfg <<'EOF'
              [preset.0]
              name="build"
              platform="Linux"
              runnable=true
              export_filter="all_resources"
              include_filter=""
              exclude_filter=""
              [preset.0.options]
              __empty=""
              EOF

              runHook postUnpack
            '';

            buildPhase = ''
              runHook preBuild

              export HOME=$(mktemp -d)
              mkdir -p $HOME/.local/share/godot/
              ln -s "${pkg.export-templates-bin}"/share/godot/export_templates "$HOME"/.local/share/godot/

              godot --headless -s create-scene.gd

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p "$out"/bin
              godot --headless --export-release build "$out"/bin/test

              runHook postInstall
            '';
          };
        in
        {
          version = testers.testVersion {
            package = pkg;
            version = dottedVersion;
          };

          project-runs = runCommand "${pkg.name}-project-runs" { } ''
            (
              set -eo pipefail
              HOME=$(mktemp -d)
              "${exportedProject}"/bin/test --headless | tail -n1 | (
                read output
                if [[ "$output" != "Hello, World!" ]]; then
                  echo "unexpected output: $output" >&2
                  exit 1
                fi
              )
              touch "$out"
            )
          '';
        };
    };

    requiredSystemFeatures = [
      # fixes: No space left on device
      "big-parallel"
    ];

    meta = {
      changelog = "https://github.com/godotengine/godot/releases/tag/${version}";
      description = "Free and Open Source 2D and 3D game engine";
      homepage = "https://godotengine.org";
      license = lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ] ++ lib.optional (!withMono) "i686-linux";
      maintainers = with lib.maintainers; [
        shiryel
        corngood
      ];
      mainProgram = "godot4${suffix}";
    };
  };

in
stdenv.mkDerivation (
  if withMono then
    dotnetCorePackages.addNuGetDeps {
      inherit nugetDeps;
      overrideFetchAttrs = old: rec {
        runtimeIds = map (system: dotnetCorePackages.systemToDotnetRid system) old.meta.platforms;
        buildInputs =
          old.buildInputs
          ++ lib.concatLists (lib.attrValues (lib.getAttrs runtimeIds dotnet-sdk.targetPackages));
      };
    } attrs
  else
    attrs
)
