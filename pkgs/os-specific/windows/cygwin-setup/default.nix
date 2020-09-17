{ lib, stdenv, fetchgit, autoconf, automake, libtool, flex, bison, pkg-config
, zlib, bzip2, xz, libgcrypt
}:

with lib;

stdenv.mkDerivation rec {
  pname = "cygwin-setup";
  version = "2.905";

  src = fetchgit {
    url = "git://cygwin.com/git/cygwin-setup.git";
    rev = "release_${version}"
    sha256 = "0240xaaxkf7p1i78bh5xrsqmfz7ss2amigbfl2r5w9h87zqn9aq3";
  };

  nativeBuildInputs = [ autoconf automake libtool flex bison pkg-config ];

  buildInputs = let
    mkStatic = flip overrideDerivation (o: {
      dontDisableStatic = true;
      configureFlags = toList (o.configureFlags or []) ++ [ "--enable-static" ];
      buildInputs = map mkStatic (o.buildInputs or []);
      propagatedBuildInputs = map mkStatic (o.propagatedBuildInputs or []);
    });
  in map mkStatic [ zlib bzip2 xz libgcrypt ];

  configureFlags = [ "--disable-shared" ];

  dontDisableStatic = true;

  preConfigure = ''
    autoreconf -vfi
  '';

  installPhase = ''
    install -vD setup.exe "$out/bin/setup.exe"
  '';

  meta = {
    homepage = "https://sourceware.org/cygwin-apps/setup.html";
    description = "A tool for installing Cygwin";
    license = licenses.gpl2Plus;
  };
}
