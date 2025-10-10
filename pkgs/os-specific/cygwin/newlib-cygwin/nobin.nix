{
  runCommand,
  newlib-cygwin,
}:

newlib-cygwin
// {
  bin = runCommand "${newlib-cygwin.name}-nobin" {} ''
    mkdir -p "$out"/bin
    CYGWIN+=\ winsymlinks:nativestrict ln -sr /bin/cygwin1.dll "$out"/bin
  '';
}
