{
  lib,
  stdenvNoLibc,
  newlib-cygwin-headers,
  buildPackages,
  automake,
  autoconf,
  autoreconfHook,
  bison,
  cocom-tool-set,
  flex,
  perl,
  w32api,
}:

stdenvNoLibc.mkDerivation {
  pname = "newlib-cygwin";

  inherit (newlib-cygwin-headers)
    version
    src
    meta
    ;

  outputs = [
    "out"
    "bin"
    "dev"
    "man"
  ];

  patches =
    newlib-cygwin-headers.patches
    ++ [
      # https://cygwin.com/pipermail/cygwin-developers/2020-September/011970.html
      # This is required for boost coroutines to work. After we get to the point
      # where nix runs on cygwin, we can attempt to upstream this again.
      ./store-tls-pointer-in-win32-tls.patch
    ]
    ++ lib.optional (stdenvNoLibc.hostPlatform != stdenvNoLibc.buildPlatform) ./fix-cross.patch;

  postPatch = ''
    patchShebangs --build winsup/cygwin/scripts
  '';

  preConfigure = ''
    pushd winsup
    aclocal --force
    autoconf -f
    automake -ac
    rm -rf autom4te.cache
    popd
    mkdir "../build"
    cd "../build"
    configureScript="../$sourceRoot/configure"
  '';

  env.CFLAGS_FOR_TARGET = toString [
    "-Wl,-L${lib.getLib w32api}${w32api.libdir or "/lib/w32api"}"
  ];

  env.CXXFLAGS_FOR_TARGET = toString [
    "-Wno-error=register"
    "-Wl,-L${lib.getLib w32api}${w32api.libdir or "/lib/w32api"}"
  ];

  strictDeps = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    autoconf
    automake
    bison
    cocom-tool-set
    flex
    perl
  ]
  ++ lib.optional (stdenvNoLibc.hostPlatform != stdenvNoLibc.buildPlatform) autoreconfHook;

  buildInputs = [ w32api ];

  makeFlags = [
    "tooldir=${placeholder "out"}"
  ];

  enableParallelBuilding = true;

  # this is explicitly -j1 in cygwin.cygport
  # without it the install order is non-deterministic
  enableParallelInstalling = false;

  hardeningDisable = [
    # conflicts with internal definition of 'bzero'
    "fortify"
    "stackprotector"
  ];

  configurePlatforms = [
    "build"
    "target"
  ];

  configureFlags = [
    "--disable-shared"
    "--disable-doc"
    "--enable-static"
    "--disable-dumper"
    "--with-cross-bootstrap"
  ]
  ++ lib.optional (stdenvNoLibc.hostPlatform != stdenvNoLibc.buildPlatform) [
    "ac_cv_prog_CC=gcc"
  ];

  allowedImpureDLLs = [
    "ADVAPI32.dll"
    "PSAPI.DLL"
    "NETAPI32.dll"
    "SHELL32.dll"
    "USER32.dll"
    "USERENV.dll"
    "dbghelp.dll"
    "ntdll.dll"
  ];

  passthru.w32api = w32api;
}
