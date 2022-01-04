{ stdenv, pkgsBuildBuild, zlib }:

let
  zlib = pkgsBuildBuild.pkgsCross.mingwW64.zlib;

in stdenv.mkDerivation rec {
  pname = "newlib-cygwin";
  version = "3.3.3";

  src = pkgsBuildBuild.fetchgit {
    url = "git://cygwin.com/git/newlib-cygwin.git";
    rev = "cygwin-3_3_3-release";
    sha256 = "sha256-Adn/y8s/eShzxlMGS0OXgybR/QYIortgFQo/gfNfhCE=";
  };

  depsBuildBuild = with pkgsBuildBuild; [
    pkgsBuildBuild.stdenv.cc
    pkgsCross.mingwW64.stdenv.cc
    autoconf
    automake
    m4
    perl
    cocom-tools
    xmlto
    dblatex
    dblatex.tex
    docbook_xsl
    docbook_xml_dtd_45
  ];

  # This can't just be an input because it looks for `docbook2x-texi`. Use
  # texinfo 6.7 because makeinfo from 6.8 seems to be broken when pipelined.
  DOCBOOK2XTEXI = with pkgsBuildBuild; "${docbook2x.override { texinfo = texinfo6_7; }}/bin/docbook2texi";

  enableParallelBuilding = true;

  # After digging through cc-wrapper, I feel like there must be a better way to
  # do this, but possibly not without changes. We need something more than just
  # _FOR_TARGET and _FOR_BUILD.
  # TODO: use inputs for multiple targets
  preHook = ''
    export NIX_CFLAGS_COMPILE_x86_64_w64_mingw32='-isystem ${zlib.dev}/include'
    export NIX_LDFLAGS_x86_64_w64_mingw32='-L${zlib.static}/lib -lz'
  '';

  prePatch = ''
      substituteInPlace winsup/doc/Makefile.am \
        --replace 'cp /usr/share/docbook2X/charmaps/texi.charmap charmap' \
        'cp ${pkgsBuildBuild.docbook2x}/share/docbook2X/charmaps/texi.charmap charmap && chmod 644 charmap'

      patchShebangs \
        newlib/libc/iconv/ccs/mktbl.pl \
        newlib/libc/iconv/ces/mkdeps.pl \
        newlib/libc/machine/spu/mk_syscalls \
        newlib/libc/string/uniset \
        winsup/cygserver/cygserver-config \
        winsup/cygwin/analyze_sigfe \
        winsup/cygwin/cygmagic \
        winsup/cygwin/dllfixdbg \
        winsup/cygwin/gendef \
        winsup/cygwin/gendevices \
        winsup/cygwin/gentls_offsets \
        winsup/cygwin/mkglobals_h \
        winsup/cygwin/mkimport \
        winsup/cygwin/sortdin \
        winsup/cygwin/speclib \
        winsup/cygwin/update-copyright \
        winsup/doc/bodysnatcher.pl \
        winsup/doc/etc.preremove.cygwin-doc.sh \
        winsup/utils/tzmap-from-unicode.org
  '';

  # newlib expects CC to build for build platform, not host platform
  preConfigure = ''
    export CC=cc
    cd winsup
    aclocal --force
    autoconf -f
    automake -ac
    cd ..
  '';

  configurePlatforms = [ "build" "target" ];
  configureFlags = [
    "--with-system-zlib"
  ];

  # stripping breaks cygwin1.dll
  # TODO: find out why
  dontStrip = true;

  passthru = {
    incdir = "/${stdenv.targetPlatform.config}/include";
    libdir = "/${stdenv.targetPlatform.config}/lib";
  };
}
