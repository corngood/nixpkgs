preFixupHooks+=(_moveCygwinDlls)

_moveCygwinDlls() {
    moveToOutput "bin/cyg*.dll" "${!outputBin}"
}
