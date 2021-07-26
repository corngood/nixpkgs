postFixupHooks+=(_linkDLLs)

declare -a cygPaths

_dllDeps() {
    objdump -p "$1" \
        | sed -n 's/.*DLL Name: \(.*\)/\1/p' \
        | sort -u
}

_linkDeps() {
    local target="$1" dir="$2" prefix="$3"
    echo 'target:' "$target"
    local dll
    while read dll; do
        echo '  dll:' "$dll"
        if [ -e "$dir/$dll" ]; then continue; fi
        # Locate the DLL - it should be an *executable* file on $DLLPATH.
        local dllPath="$(PATH="$(dirname "$target"):$DLLPATH" type -P "$dll")"
        if [ -z "$dllPath" ]; then continue; fi
        dllPath="$(readlink -f "$dllPath")"
        if [[ "$symlinkTarget"/ == "$prefix"/* ]]; then
            dllPath="$(realpath -s --relative-to="$dir" "$dllPath")"
        fi
        echo '    linking to:' "$dllPath"
        CYGWIN+=\ winsymlinks:nativestrict ln -s "$dllPath" "$dir"
        linkCount=$(($linkCount+1))
        # That DLL might have its own (transitive) dependencies,
        # so add also all DLLs from its directory to be sure.
        _linkDeps "$dllPath" "$dir" "$prefix"
    done < <(_dllDeps "$target")
}

# For every *.{exe,dll} in $output/bin/ we try to find all (potential)
# transitive dependencies and symlink those DLLs into $output/bin
# so they are found on invocation.
# (DLLs are first searched in the directory of the running exe file.)
# The links are relative, so relocating whole /nix/store won't break them.
_linkDLLs() {
(
    set -e
    shopt -s globstar nullglob

    # Compose path list where DLLs should be located:
    #   prefix $PATH by currently-built outputs
    local DLLPATH=""
    local outName
    for outName in $outputs; do
        addToSearchPath DLLPATH "${!outName}/bin"
    done
    DLLPATH+=":$PATH"

    for outName in $outputs; do
        local prefix=${!outName}
        [ ! -e "$prefix" ] && return
        cd "$prefix"

        local linkCount=0
        # Iterate over any DLL that we depend on.
        local target
        for target in {bin,libexec}/**/*.{exe,dll}; do
            _linkDeps "$target" "$(dirname "$target")" "$prefix"
        done
    done
)
}
