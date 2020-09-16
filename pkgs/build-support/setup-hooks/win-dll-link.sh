
fixupOutputHooks+=(_linkDLLs)

declare -a cygPaths

# For every *.{exe,dll} in $output/bin/ we try to find all (potential)
# transitive dependencies and symlink those DLLs into $output/bin
# so they are found on invocation.
# (DLLs are first searched in the directory of the running exe file.)
# The links are relative, so relocating whole /nix/store won't break them.
_linkDLLs() {
(
    set -e
    shopt -s globstar nullglob

    [ ! -e "$prefix" ] && return
    cd "$prefix"

    # Compose path list where DLLs should be located:
    #   prefix $PATH by currently-built outputs
    local DLLPATH=""
    local outName
    for outName in $outputs; do
        addToSearchPath DLLPATH "${!outName}/bin"
    done
    local path
    for path in "${cygPaths[@]}"; do
        addToSearchPath DLLPATH "$path"
    done

    local linkCount=0
    # Iterate over any DLL that we depend on.
    local target
    for target in {bin,libexec}/**/*.{exe,dll}; do
        echo executable: $target
        local dir=$(dirname "$target")
        local dll
        while read dll; do
            echo '  dll:' "$dll"
            if [ -e "$dir/$dll" ]; then continue; fi
            # Locate the DLL - it should be an *executable* file on $DLLPATH.
            local dllPath="$(PATH="$DLLPATH" type -P "$dll")"
            if [ -z "$dllPath" ]; then continue; fi
            # That DLL might have its own (transitive) dependencies,
            # so add also all DLLs from its directory to be sure.
            local dllPath2
            for dllPath2 in "$dllPath" "$(dirname $(readlink "$dllPath" || echo "$dllPath"))"/*.dll; do
                if [ -e "$dir/$(basename "$dllPath2")" ]; then continue; fi
                CYGWIN+=\ winsymlinks:nativestrict ln -sr "$dllPath2" "$dir"
                echo '  link:' "$dllPath2"
                linkCount=$(($linkCount+1))
            done
        done < <(objdump -p "$target" \
                     | sed -n 's/.*DLL Name: \(.*\)/\1/p' \
                     | sort -u)
    done
)
}

addPkgToCygPaths() {
    cygPaths+=("$1/bin")
}

addEnvHooks "$targetOffset" addPkgToCygPaths
