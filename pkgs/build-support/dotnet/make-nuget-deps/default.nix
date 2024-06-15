{ symlinkJoin
, fetchurl
, stdenvNoCC
, stdenv
, lib
, unzip
, dotnetCorePackages
, zlib
, curl
, icu
, libunwind
, libuuid
, openssl
, lttng-ust_2_12
}:
{ name, nugetDeps ? import sourceFile, sourceFile ? null }:
(symlinkJoin {
  name = "${name}-nuget-deps";
  paths = nugetDeps {
    fetchNuGet =
      { pname
      , version
      , sha256
      , url ? "https://www.nuget.org/api/v2/package/${pname}/${version}" }:
      stdenvNoCC.mkDerivation rec {
        inherit pname version;

        src = fetchurl {
          name = "${pname}.${version}.nupkg";
          inherit url sha256 version;
        };

        nativeBuildInputs = [
          unzip
        ];

        unpackPhase = ''
          unzip -q $src
          chmod -R +rw .
        '';

        prePatch = ''
         [[ ! -d tools ]] || chmod -R +x tools
       '';

        installPhase = ''
          dir=$out/share/nuget/packages/${lib.toLower pname}/${lib.toLower version}
          mkdir -p $dir
          cp -r . $dir
          echo {} > "$dir"/.nupkg.metadata
        '';

        preFixup = let
          buildRid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.buildPlatform.system;

          binaryRPath = lib.makeLibraryPath ([
            stdenv.cc.cc
            zlib
            curl
            icu
            libunwind
            libuuid
            openssl
          ] ++ lib.optional stdenvNoCC.isLinux lttng-ust_2_12);
          in ''
          pushd $out/share/nuget/packages
          for x in *.${buildRid}/* *.${buildRid}.*/*; do
            # .nupkg.metadata is written last, so we know the packages is complete
            [[ -d "$x" ]] && [[ -f "$x"/.nupkg.metadata ]] \
              && [[ ! -f "$x"/.nix-patched ]] || continue
            echo "Patching package $x"
            pushd "$x"
            for p in $(find -type f); do
              if [[ "$p" != *.nix-patched ]] \
                && isELF "$p" \
                && patchelf --print-interpreter "$p" &>/dev/null; then
                tmp="$p".$$.nix-patched
                # if this fails to copy then another process must have patched it
                cp --reflink=auto "$p" "$tmp" || continue
                echo "Patchelfing $p as $tmp"
                patchelf \
                  --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
                  "$tmp" ||:
                # This makes sure that if the binary requires some specific runtime dependencies, it can find it.
                # This fixes dotnet-built binaries like crossgen2
                patchelf \
                  --add-needed libicui18n.so \
                  --add-needed libicuuc.so \
                  --add-needed libz.so \
                  --add-needed libssl.so \
                  "$tmp"
                patchelf \
                  --add-rpath "${binaryRPath}" \
                  "$tmp" ||:
                mv "$tmp" "$p"
              fi
            done
            touch .nix-patched
            popd
          done
          popd
        '';
      };
    };
}) // {
  inherit sourceFile;
}
