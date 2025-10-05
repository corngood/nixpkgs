{
  lib,
  stdenv,
  fetchurl,
  updateAutotoolsGnuConfigScriptsHook,
  # Causes consistent segfaults on ELFv1 PPC64 when trying to use Perl regex in gnugrep
  # https://github.com/PCRE2Project/pcre2/issues/762
  withJitSealloc ? !(stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isAbiElfv1),
}:

stdenv.mkDerivation rec {
  pname = "pcre2";
  version = if stdenv.hostPlatform.isCygwin then "10.46" else "10.44";

  src = fetchurl {
    url = "https://github.com/PhilipHazel/pcre2/releases/download/pcre2-${version}/pcre2-${version}.tar.bz2";
    hash =
      if stdenv.hostPlatform.isCygwin then
        "sha256-FfvFq6a+7gsXrssEYCrjlDI5OroevY45t8q/fbiDKZ8="
      else
        "sha256-008C4RPPcZOh6/J3DTrFJwiNSF1OBH7RDl0hfG713pY=";
  };

  ${if stdenv.hostPlatform.isCygwin then "patches" else null} =
    lib.optional stdenv.hostPlatform.isCygwin
      (fetchurl {
        url = "https://cygwin.com/cgit/cygwin-packages/pcre2/plain/pcre2-10.46-cygwin-jit.patch";
        hash = "sha256-9WoKxyCpmKdFfSFZAbtLJ8yrGphPfB+xf/CPqscSivY=";
      });
  ${if stdenv.hostPlatform.isCygwin then "patchFlags" else null} = [ "-p2" ];

  nativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];

  configureFlags = [
    "--enable-pcre2-16"
    "--enable-pcre2-32"
    # only enable jit on supported platforms which excludes Apple Silicon, see https://github.com/zherczeg/sljit/issues/51
    "--enable-jit=${if stdenv.hostPlatform.isS390x then "no" else "auto"}"
  ]
  # fix pcre jit in systemd units that set MemoryDenyWriteExecute=true like gitea
  ++ lib.optional withJitSealloc "--enable-jit-sealloc";

  outputs = [
    "bin"
    "dev"
    "out"
    "doc"
    "man"
    "devdoc"
  ];

  postFixup = ''
    moveToOutput bin/pcre2-config "$dev"
  '';

  meta = with lib; {
    homepage = "https://www.pcre.org/";
    description = "Perl Compatible Regular Expressions";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ttuegel ];
    platforms = platforms.all;
    pkgConfigModules = [
      "libpcre2-posix"
      "libpcre2-8"
      "libpcre2-16"
      "libpcre2-32"
    ];
  };
}
