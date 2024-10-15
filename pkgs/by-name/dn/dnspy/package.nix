{
  lib,
  stdenvNoCC,
  lndir,
  pkgsCross,
  is32bit ? false,
  wine,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  writeShellScript,
  nix-update,
}:
stdenvNoCC.mkDerivation rec {
  pname = "dnspy${lib.optionalString is32bit "32"}";
  version = "6.5.1";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  unwrapped =
    (if is32bit then pkgsCross.mingw32 else pkgsCross.mingwW64).callPackage ./unwrapped.nix
      {
        inherit pname version is32bit;
      };

  wrapper = writeShellScript "dnspy-wrapper" ''
    export WINE="${lib.getExe wine}"
    export WINEPREFIX="''${DNSPY_HOME:-"''${XDG_DATA_HOME:-"''${HOME}/.local/share"}/dnSpy"}/wine${lib.optionalString is32bit "32"}"
    export WINEDEBUG=-all

    if [ ! -d "$WINEPREFIX" ]; then
      mkdir -p "$WINEPREFIX"
      ${lib.getExe' wine "wineboot"} -u
    fi

    exec "$WINE" "''${ENTRYPOINT:-@out@/lib/${unwrapped.pname}/dnSpy.exe}" "$@"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    ${lib.getExe lndir} -silent ${unwrapped} $out

    mkdir $out/bin
    cp ${wrapper} $out/bin/${meta.mainProgram}
    substituteInPlace $out/bin/${meta.mainProgram} \
      --subst-var-by out $out

    runHook postInstall
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    desktopName = "dnSpy" + (lib.optionalString is32bit " (32-bit)");
    comment = meta.description;
    icon = pname;
    exec = meta.mainProgram;
    categories = [ "Development" ];
  };

  passthru.updateScript = writeShellScript "update-dnspy" ''
    ${lib.getExe nix-update} "dnspy.unwrapped"
    "$(nix-build -A "dnspy.unwrapped.fetch-deps" --no-out-link)"
  '';

  meta = unwrapped.meta // {
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
