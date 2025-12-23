{
  pkgs ? import ../../.. { },
}:
let
  inherit (pkgs) runCommand;
  # splicing doesn't seem to work right here
  inherit (pkgs.buildPackages) dumpnar rsync;

  pack-env =
    paths:
    pkgs.buildEnv {
      name = "pack-env";
      paths = paths;
      includeClosures = true;
      ignoreCollisions = true;
    };

  pack-all =
    packCmd: name: pkgs: fixups:
    (runCommand name
      {
        nativeBuildInputs = [
          rsync
          dumpnar
        ];
      }
      (
        let
        in
        ''
          rsync --chmod="+w" -av --safe-links --exclude=cygwin1.dll "${pack-env pkgs}"/ .

          base=$PWD
          rm -rf nix nix-support
          mkdir nix-support
          for dir in $requisites; do
            cd "$dir/nix-support" 2>/dev/null || continue
            for f in $(find . -type f); do
              mkdir -p "$base/nix-support/$(dirname $f)"
              cat $f >>"$base/nix-support/$f"
            done
          done
          rm -f $base/nix-support/propagated-build-inputs
          cd $base

          ${fixups}

          ${packCmd}
        ''
      )
    );
  nar-all = pack-all "dumpnar . | xz -9 -e -T $NIX_BUILD_CORES >$out";
  tar-all = pack-all "XZ_OPT=\"-9 -e -T $NIX_BUILD_CORES\" tar cJf $out --hard-dereference --sort=name --numeric-owner --owner=0 --group=0 --mtime=@1 .";
  coreutils-big = pkgs.coreutils.override { singleBinary = false; };
  mkdir = runCommand "mkdir" { coreutils = coreutils-big; } ''
    mkdir -p $out/bin
    cp $coreutils/bin/mkdir.exe $out/bin
  '';

  curl = pkgs.curl.overrideAttrs (old: {
    # these use the build shebang
    # TODO: fix in curl
    postFixup = old.postFixup or "" + ''
      rm "$dev"/bin/curl-config "$bin"/bin/wcurl
    '';
  });

  inherit (pkgs)
    bashNonInteractive
    binutils-unwrapped
    bzip2
    coreutils
    findutils
    gawk
    gcc-unwrapped
    gitMinimal # for fetchgit (newlib-cygwin)
    gnugrep
    gnumake
    gnused
    gnutar
    gzip
    patch
    ;

in
rec {
  bootstrap-env = pack-env (
    with pkgs;
    [
      bashNonInteractive
      binutils-unwrapped
      coreutils
      gnugrep
      curl
      gcc-unwrapped
      gitMinimal # for fetchgit (newlib-cygwin)
      findutils
      patch
    ]
  );

  unpacked =
    runCommand "unpacked"
      {
        nativeBuildInputs = [ rsync ];
        # The result should not contain any references (store paths) so
        # that we can safely copy them out of the store and to other
        # locations in the store.
        # TODO:
        # allowedReferences = [ ];
      }
      ''
        mkdir -p "$out"/{bin,include,lib,libexec}
        cp -d "${bashNonInteractive}"/bin/* "$out"/bin/
        cp -d "${binutils-unwrapped}"/bin/* "$out"/bin/
        cp -d "${bzip2}"/bin/* "$out"/bin/
        cp -d "${coreutils}"/bin/* "$out"/bin/
        cp -d "${curl}"/bin/* "$out"/bin/
        cp -d "${findutils}"/bin/* "$out"/bin/
        cp -d "${gawk}"/bin/* "$out"/bin/
        cp -d "${gcc-unwrapped}"/bin/* "$out"/bin/
        cp -rd ${gcc-unwrapped}/include/* $out/include/
        cp -rd ${gcc-unwrapped}/lib/* $out/lib/
        cp -rd ${gcc-unwrapped}/libexec/* $out/libexec/
        cp -d "${gitMinimal}"/bin/* "$out"/bin/
        cp -d "${gnugrep}"/bin/* "$out"/bin/
        cp -d "${gnumake}"/bin/* "$out"/bin/
        cp -d "${gnused}"/bin/* "$out"/bin/
        cp -d "${gnutar}"/bin/* "$out"/bin/
        cp -d "${gzip}"/bin/* "$out"/bin/
        cp -d "${patch}"/bin/* "$out"/bin/

        for x in "$out"/bin/* "$out"/libexec/*/*/*; do
          [[ -L "$x" && -e "$x" ]] || continue
          [[ $(realpath "$x") != "$out"* ]] || continue
          cp "$x" "$x"~
          mv "$x"~ "$x"
        done
      '';

  unpack = nar-all "unpack.nar.xz" (with pkgs; [
    bashNonInteractive
  ]) "";
  bootstrap-tools = tar-all "bootstrap-tools.tar.xz" (with pkgs; [
    gcc
    # gcc.lib
    curl
    curl.dev
    cygwin.newlib-cygwin
    cygwin.newlib-cygwin.bin
    cygwin.newlib-cygwin.dev
    cygwin.w32api
    cygwin.w32api.dev
    # bintools-unwrapped
    gnugrep
    coreutils
    expand-response-params
  ]) "";
  build = runCommand "build" { } ''
    mkdir -p $out/on-server
    ln -s ${unpack} $out/on-server/unpack.nar.xz
  '';
}
