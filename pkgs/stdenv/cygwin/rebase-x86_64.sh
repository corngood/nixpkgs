fixupOutputHooks+=(_cygwinFixAutoImageBase)

_cygwinGetImageBase() {
    printf \
        '0x%x\n' \
        $(( \
            $((0x$(echo "$1" | sha1sum | cut -c1-15) & 0x7fffffffffff0000)) \
                % $((0x770000000000 - 0x400000000)) + 0x400000000 \
         ))
}

_cygwinFixAutoImageBase() {
    if [ "${dontRebase-}" == 1 ] || [ ! -d "$prefix" ]; then
        return
    fi
    find "$prefix" -name "*.dll" -type f | while read DLL; do
        NEXTBASE=${NEXTBASE:-$(_cygwinGetImageBase "$prefix")}

        REBASE=(`/bin/rebase -i $DLL`)
        BASE=${REBASE[2]}
        SIZE=${REBASE[4]}
        SKIP=$(((($SIZE>>16)+1)<<16))

        echo "REBASE FIX: $DLL $BASE -> $NEXTBASE"
        /bin/rebase -b $NEXTBASE $DLL
        NEXTBASE="0x`printf %x $(($NEXTBASE+$SKIP))`"
    done
}
