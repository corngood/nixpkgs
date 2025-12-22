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
      postBuild = ''
        rm "$out"/bin/cygwin1.dll
      '';
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
          cp -aLT "${pack-env pkgs}" .
          chmod -R +w .

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
in
rec {
  unpack = nar-all "unpack.nar.xz" (with pkgs; [
    bash
    mkdir
    xz
    gnutar
  ]) "";
  bootstrap-tools = tar-all "bootstrap-tools.tar.xz" (with pkgs; [
    coreutils
  ]) "";
  build = runCommand "build" { } ''
    mkdir -p $out/on-server
    ln -s ${unpack} $out/on-server/unpack.nar.xz
    ln -s ${bootstrap-tools} $out/on-server/bootstrap-tools.tar.xz
  '';
}
