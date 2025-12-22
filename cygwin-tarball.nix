{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (pkgs)
    bash
    buildEnv
    buildPackages
    coreutils
    cygwin
    gnutar
    lib
    runCommand
    writeShellScript
    writeText
    ;

  nix = config.nix.package;

  # These are here so the cross stdenv will work. This is a bit hacky because
  # these are not pinned and will only work with this nixpkgs.
  stdenvDeps = (import ./. { system = "x86_64-cygwin"; }).__bootstrapPackages;

  sw = buildEnv {
    name = "cygwin-root";

    paths = config.environment.systemPackages;

    nativeBuildInputs = [
      ./pkgs/build-support/setup-hooks/make-symlinks-relative.sh
    ];
  };

  bootScript = writeText "cygwin.ps1" (
    lib.replaceString "\n" "\r\n" ''
      $ErrorActionPreference = 'Stop'
      $bash = "$PSScriptRoot${lib.replaceString "/" "\\" (lib.getBin bash).outPath}\bin\bash.exe"
      & $bash /nix/var/nix/profiles/system/activate
      if (!$?) { throw 'activation script failed' }
      & $bash --login -i $args
      if (!$?) { exit 1 }
    ''
  );

  cygwin1 = lib.getBin cygwin.newlib-cygwin.out + "/bin/cygwin1.dll";

  activate = writeShellScript "activate" ''
    (
      export PATH=${
        lib.makeBinPath [
          coreutils
          nix
        ]
      }:/bin
      mkdir -p /nix/var/nix/gcroots
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system
      mkdir -p /run
      ln -sfn '${lib.getExe bash}' /bin/sh
      ln -sfn '@out@' /run/current-system
      ln -sfn /run/current-system/etc /etc
      if [[ -f /nix-path-registration ]]; then
        nix-store --load-db < /nix-path-registration
        rm /nix-path-registration
      fi
    )
  '';

in
{
  options.system.build.tarball = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
  };

  config = {
    environment.etc."profile".text = ''
      export PATH=/run/current-system/sw/bin:/bin:$PATH
      export CYGWIN=winsymlinks=native\ $CYGWIN
    '';

    system.build = {
      toplevel = runCommand "cygwin-system" { } ''
        mkdir "$out"
        ln -sr "${sw}" "$out"/sw
        cp "${activate}" "$out"/activate
        substituteInPlace $out/activate --subst-var-by out "$out"
        ln -sr "${config.system.build.etc}"/etc $out/etc
      '';

      tarball =
        let
          install = writeText "install.ps1" (
            lib.replaceString "\n" "\r\n" ''
              param ([Parameter(Mandatory=$true)][string]$dir)

              $ErrorActionPreference = 'Stop'

              $_ = mkdir -force $dir

              fsutil file setCaseSensitiveInfo $dir enable
              if (!$?) { throw 'setCaseSensitiveInfo failed, this may require: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux' }

              $_ = ni $dir\.test-target
              try {
                cmd /c mklink $dir\.test-link $dir\.test-target
                if (!$?) {
                  throw 'failed to create symbolic link: developer mode may need to be enabled'
                }
              } catch {
                  throw
              } finally {
                  rm $dir\.test-target
              }
              rm $dir\.test-link

              $env:CYGWIN = "winsymlinks=native"
              & $PSScriptRoot\tar -C $dir --force-local -xpf $PSScriptRoot\${config.system.build.tarball.fileName}.tar${config.system.build.tarball.extension}
              if (!$?) { throw 'failed to extract tarball' }
            ''
          );

          system = config.system.build.toplevel;
        in
        (pkgs.callPackage nixos/lib/make-system-tarball.nix {
          # HACK: disable compression
          compressCommand = "cat";
          compressionExtension = "";

          contents = [
            {
              source = cygwin1;
              target = "/bin/cygwin1.dll";
            }
            {
              source = bootScript;
              target = "cygwin.ps1";
            }
          ];

          storeContents = [
            {
              object = system;
              symlink = "none";
            }
          ]
          ++ map (object: {
            inherit object;
            symlink = "none";
          }) stdenvDeps;

          extraCommands = buildPackages.writeShellScript "extra-commands.sh" ''
            chmod -R +w nix
            mkdir -p tmp nix/var/nix/profiles dev
            mkdir -m 01777 dev/{shm,mqueue}
            ln -s "$(realpath -s --relative-to=/nix/var/nix/profiles "${system}")" nix/var/nix/profiles/system
            find . -type l -print0 | while read -r -d "" f; do
                symlinkTarget=$(readlink "$f")
                if [[ "$symlinkTarget"/ != /nix/store* ]]; then
                    # skip this symlink as it doesn't point to /nix/store
                    continue
                fi

                relativeTarget=''${symlinkTarget#/}

                if [ ! -e "$relativeTarget" ]; then
                    echo "the symlink $f is broken, it points to $relativeTarget (which is missing)"
                fi

                relativeTarget=$(realpath -s --relative-to=$(dirname "$f") "$relativeTarget")

                echo "changing symlink $f -> $symlinkTarget to $relativeTarget"
                ln -snf "$relativeTarget" "$f"
            done

            mkdir -p "$out"/tarball
            cp "${install}" "$out"/tarball/install.ps1
            cp "${gnutar}/bin/tar.exe" "$out"/tarball/
            for dll in "${gnutar}/bin"/*.dll; do
              if [[ $dll != */cygwin1.dll ]]; then
                cp "$dll" "$out"/tarball/
              fi
            done
            cp "${cygwin1}" "$out"/tarball/
          '';
        })
        // {
          inherit system;
          stdenvDeps = pkgs.writeText "foo" (toString stdenvDeps);
        };
    };
  };
}
