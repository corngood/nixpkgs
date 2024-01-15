{ stdenv
, stdenvNoCC
, callPackage
, lib
, writeShellScript
, pkgsBuildHost
, mkNugetDeps
, cacert
, nuget-to-nix
, dotnetCorePackages
, darwin

, releaseManifest
, hash
, prepDepsFile
, buildDepsFile
, bootstrapSdk
}:

let
  mkPackages = callPackage ./packages.nix;
  mkVMR = callPackage ./vmr.nix;

  dotnetSdk = pkgsBuildHost.callPackage bootstrapSdk {};

  patchNupkgs = pkgsBuildHost.callPackage ./patch-nupkgs.nix {};

  vmr = (mkVMR {
    inherit releaseManifest hash dotnetSdk;
  }).overrideAttrs (old: rec {
    prepDeps = mkNugetDeps {
      name = "${old.pname}-prep";
      sourceFile = prepDepsFile;
    };

    buildDeps = mkNugetDeps {
      name = "${old.pname}-build";
      sourceFile = buildDepsFile;
    };

    patches = old.patches or [] ++ [
      # In some builds, Newtonsoft.Json.dll is marked as missing a pdb, but it
      # appears to be non-deterministic.
      ./allow-missing-pdbs.patch
      ./use-nuget-deps.patch
      ./patch-restored-packages.patch
    ]
    ++ lib.optional stdenv.isDarwin ./sign-apphost.patch;

    nativeBuildInputs = old.nativeBuildInputs ++ [
      patchNupkgs
    ];

    # TODO: fix this in the binary sdk packages
    prePatch = old.prePatch or ""
    + lib.optionalString stdenv.isDarwin ''
      addToSearchPath DYLD_LIBRARY_PATH "${darwin.ICU}/lib"
      export DYLD_LIBRARY_PATH
    '';

    postConfigure = old.postConfigure or "" + ''
      [[ ! -v buildDeps ]] || ln -sf "$buildDeps"/* prereqs/packages/prebuilt/
    '';

    passthru = old.passthru or {} // { fetch-deps =
      let
        inherit (vmr) targetRid updateScript;
        otherRids =
          lib.remove targetRid (
            map (system: dotnetCorePackages.systemToDotnetRid system)
              vmr.meta.platforms);

        pkg = vmr.overrideAttrs (old: {
          patches = old.patches or [] ++ [
            ./record-downloaded-packages.patch
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            cacert
            (nuget-to-nix.override { dotnet-sdk = dotnetSdk; })
          ];
          buildFlags = [ "--online" ] ++ old.buildFlags;
          prepDeps = null;
          buildDeps = null;
        });

        drv = builtins.unsafeDiscardOutputDependency pkg.drvPath;
      in
        writeShellScript "fetch-dotnet-sdk-deps" ''
          set -euo pipefail
          export PATH="${with pkgsBuildHost; lib.makeBinPath [ nix ]}":$PATH

          tmp=$(mktemp -d)
          trap 'rm -fr "$tmp"' EXIT

          HOME=$tmp/.home
          cd "$tmp"

          nix-shell --pure --run 'source /dev/stdin' "${drv}" << 'EOF'
          set -e
          phases="''${prePhases[*]:-} unpackPhase patchPhase ''${preConfigurePhases[*]:-} \
            configurePhase ''${preBuildPhases[*]:-} buildPhase checkPhase" \
            genericBuild
          EOF

          cp source/prereqs/packages/archive/deps.nix "${toString prepDeps.sourceFile}"
          echo [ source/src/*/artifacts/buildLogs/source-build/self/deps.nix ] > deps-list.nix
          cp $(nix-build ${toString ./combine-deps.nix} \
            --argstr list "$PWD/deps-list.nix" \
            --argstr baseRid ${targetRid} \
            --arg otherRids '${lib.generators.toPretty { multiline = false; } otherRids}' \
            ) "${toString buildDeps.sourceFile}"
        '';
    };
  });
in mkPackages { inherit vmr; }
