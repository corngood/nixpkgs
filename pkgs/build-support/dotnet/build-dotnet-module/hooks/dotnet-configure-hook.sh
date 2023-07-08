declare -a projectFile testProjectFile packageDirs

addNugetFallbackPath() {
    local path="$1/share/nuget/packages"
    if [[ -e "$path" ]]
    then
        packageDirs+=("$path")
        addToSearchPathWithCustomDelimiter \; NUGET_FALLBACK_PACKAGES "$path"
    fi
}

addEnvHooks "$targetOffset" addNugetFallbackPath

# Inherit arguments from derivation
dotnetFlags=( ${dotnetFlags[@]-} )
dotnetRestoreFlags=( ${dotnetRestoreFlags[@]-} )

dotnetConfigureHook() {
    echo "Executing dotnetConfigureHook"

    runHook preConfigure

    if [ -z "${enableParallelBuilding-}" ]; then
        local -r parallelFlag="--disable-parallel"
    fi

    source=$(mktemp -d)

    dotnetRestore() {
        local -r project="${1-}"
        dotnet restore ${project-} \
            -p:ContinuousIntegrationBuild=true \
            -p:Deterministic=true \
            --runtime "@runtimeId@" \
            ${parallelFlag-} \
            ${dotnetRestoreFlags[@]} \
            ${dotnetFlags[@]} \
            --source "$source" \
            -v:d
    }

    # dotnet tool restore doesn't seem to understand NUGET_FALLBACK_PACKAGES
    local -r all_packages="$HOME/.nuget/all_packages"
    mkdir -p "$all_packages"
    for p in "${packageDirs[@]}"
    do
        lndir -silent $p "$all_packages"
    done

    NUGET_PACKAGES="$all_packages" dotnet tool restore

    (( "${#projectFile[@]}" == 0 )) && dotnetRestore

    for project in ${projectFile[@]} ${testProjectFile[@]-}; do
        dotnetRestore "$project"
    done

    # echo "Fixing up native binaries..."
    # # Find all native binaries and nuget libraries, and fix them up,
    # # by setting the proper interpreter and rpath to some commonly used libraries
    # for binary in $(find "$HOME/.nuget/packages/" -type f -executable); do
    #     if patchelf --print-interpreter "$binary" >/dev/null 2>/dev/null; then
    #         echo "Found binary: $binary, fixing it up..."
    #         patchelf --set-interpreter "$(cat "@dynamicLinker@")" "$binary"

    #         # This makes sure that if the binary requires some specific runtime dependencies, it can find it.
    #         # This fixes dotnet-built binaries like crossgen2
    #         patchelf \
    #             --add-needed libicui18n.so \
    #             --add-needed libicuuc.so \
    #             --add-needed libz.so \
    #             --add-needed libssl.so \
    #             "$binary"

    #         patchelf --set-rpath "@libPath@" "$binary"
    #     fi
    # done

    runHook postConfigure

    echo "Finished dotnetConfigureHook"
}

if [[ -z "${dontDotnetConfigure-}" && -z "${configurePhase-}" ]]; then
    configurePhase=dotnetConfigureHook
fi
