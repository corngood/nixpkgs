dotnetInstallHook() {
    echo "Executing dotnetInstallHook"

    runHook preInstall

    local -r hostRuntimeId=@runtimeId@
    local -r dotnetInstallPath="${dotnetInstallPath-$out/lib/$pname}"
    local -r dotnetBuildType="${dotnetBuildType-Release}"
    local -r dotnetRuntimeId="${dotnetRuntimeId-$hostRuntimeId}"

    if [[ -n $__structuredAttrs ]]; then
        local dotnetProjectFilesArray=( "${dotnetProjectFiles[@]}" )
        local dotnetFlagsArray=( "${dotnetFlags[@]}" )
        local dotnetInstallFlagsArray=( "${dotnetInstallFlags[@]}" )
        local dotnetPackFlagsArray=( "${dotnetPackFlags[@]}" )
    else
        local dotnetProjectFilesArray=($dotnetProjectFiles)
        local dotnetFlagsArray=($dotnetFlags)
        local dotnetInstallFlagsArray=($dotnetInstallFlags)
        local dotnetPackFlagsArray=($dotnetPackFlags)
    fi

    if [[ -n ${dotnetSelfContainedBuild-} ]]; then
        dotnetInstallFlagsArray+=("--self-contained")
    else
        dotnetInstallFlagsArray+=("--no-self-contained")
        # https://learn.microsoft.com/en-us/dotnet/core/deploying/trimming/trim-self-contained
        # Trimming is only available for self-contained build, so force disable it here
        dotnetInstallFlagsArray+=("-p:PublishTrimmed=false")
    fi

    if [[ -n ${dotnetUseAppHost-} ]]; then
        dotnetInstallFlagsArray+=("-p:UseAppHost=true")
    fi

    if [[ -n ${enableParallelBuilding-} ]]; then
        local -r maxCpuFlag="$NIX_BUILD_CORES"
    else
        local -r maxCpuFlag="1"
    fi

    dotnetPublish() {
        local -r projectFile="${1-}"

        runtimeIdFlagsArray=()
        if [[ $projectFile == *.csproj || -n ${dotnetSelfContainedBuild-} ]]; then
            runtimeIdFlagsArray+=("--runtime" "$dotnetRuntimeId")
        fi

        dotnet publish ${1+"$projectFile"} \
            -maxcpucount:"$maxCpuFlag" \
            -p:ContinuousIntegrationBuild=true \
            -p:Deterministic=true \
            -p:OverwriteReadOnlyFiles=true \
            --output "$dotnetInstallPath" \
            --configuration "$dotnetBuildType" \
            --no-build \
            "${runtimeIdFlagsArray[@]}" \
            "${dotnetInstallFlagsArray[@]}" \
            "${dotnetFlagsArray[@]}"
    }

    local pkgs
    pkgs=$(mktemp -d)
    trap "rm -rf $pkgs" EXIT

    dotnetPack() {
        local -r projectFile="${1-}"
        dotnet pack ${1+"$projectFile"} \
            -maxcpucount:"$maxCpuFlag" \
            -p:ContinuousIntegrationBuild=true \
            -p:Deterministic=true \
            -p:OverwriteReadOnlyFiles=true \
            --output $pkgs \
            --configuration "$dotnetBuildType" \
            --no-build \
            --runtime "$dotnetRuntimeId" \
            "${dotnetPackFlagsArray[@]}" \
            "${dotnetFlagsArray[@]}"
    }

    if (( ${#dotnetProjectFilesArray[@]} == 0 )); then
        dotnetPublish
    else
        local projectFile
        for projectFile in "${dotnetProjectFilesArray[@]}"; do
            dotnetPublish "$projectFile"
        done
    fi

    if [[ -n ${packNupkg-} ]]; then
        if (( ${#dotnetProjectFilesArray[@]} == 0 )); then
            dotnetPack
        else
            local projectFile
            for projectFile in "${dotnetProjectFilesArray[@]}"; do
                dotnetPack "$projectFile"
            done
        fi
    fi

    for nupkg in "$pkgs"/*.nupkg; do
        local -r unpacked="$pkgs/.unpacked"
        rm -rf "$unpacked"
        unzip -qd "$unpacked" "$nupkg"
        chmod -R +rw "$unpacked"
        echo {} > "$unpacked"/.nupkg.metadata
        local id version
        id=$(xq -r '.package.metadata.id|ascii_downcase' "$unpacked"/*.nuspec)
        version=$(xq -r '.package.metadata.version|ascii_downcase' "$unpacked"/*.nuspec)
        mkdir -p $out/share/nuget/packages/"$id"
        mv "$unpacked" $out/share/nuget/packages/"$id"/"$version"
    done

    runHook postInstall

    echo "Finished dotnetInstallHook"
}

if [[ -z "${dontDotnetInstall-}" && -z "${installPhase-}" ]]; then
    installPhase=dotnetInstallHook
fi
