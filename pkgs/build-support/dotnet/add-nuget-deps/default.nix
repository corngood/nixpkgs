{
  writeShellScript,
  runtimeShell,
  nix,
  lib,
  substituteAll,
  nuget-to-nix,
  cacert,
  fetchNupkg,
  callPackage,
}:

{
nugetDeps,
}:
drv:
let
  deps =
    if (nugetDeps != null) then
      if lib.isDerivation nugetDeps then
        [ nugetDeps ]
      else if lib.isList nugetDeps then
        nugetDeps
      else
        assert (lib.isPath nugetDeps);
        callPackage nugetDeps { fetchNuGet = fetchNupkg; }
    else
      [ ];

in
drv.overrideAttrs (
  self: old: {
    buildInputs = old.buildInputs or [ ] ++ deps;

    passthru =
      old.passthru or { }
      // {
        nugetDeps = deps;
      }
      // lib.optionalAttrs (nugetDeps == null || lib.isPath nugetDeps) rec {
        fetch-drv =
          let
            pkg' = drv.overrideAttrs (old: {
              buildInputs = old.buildInputs or [ ];
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ cacert ];
              keepNugetConfig = true;
              dontBuild = true;
              doCheck = false;
              dontInstall = true;
              doInstallCheck = false;
              dontFixup = true;
              doDist = false;
            });
          in
          pkg'; # .overrideAttrs overrideFetchAttrs;
        fetch-deps =
          let
            drvPath = builtins.unsafeDiscardOutputDependency self.passthru.fetch-drv.drvPath;

            innerScript = substituteAll {
              src = ./fetch-deps.sh;
              isExecutable = true;
              inherit cacert;
              nugetToNix = nuget-to-nix;
            };

            defaultDepsFile =
              # Wire in the depsFile such that running the script with no args
              # runs it agains the correct deps file by default.
              # Note that toString is necessary here as it results in the path at
              # eval time (i.e. to the file in your local Nixpkgs checkout) rather
              # than the Nix store path of the path after it's been imported.
              if lib.isPath nugetDeps && !lib.isStorePath nugetDeps then
                toString nugetDeps
              else
                ''$(mktemp -t "${drv.pname or drv.name}-deps-XXXXXX.nix")'';

          in
          writeShellScript "${drv.name}-fetch-deps" ''
            set -eu

            echo 'fetching dependencies for' ${lib.escapeShellArg drv.name} >&2

            # this needs to be before TMPDIR is changed, so the output isn't deleted
            # if it uses mktemp
            depsFile=$(realpath "''${1:-${lib.escapeShellArg defaultDepsFile}}")

            export TMPDIR
            TMPDIR=$(mktemp -d -t fetch-deps-${lib.escapeShellArg drv.name}.XXXXXX)
            trap 'chmod -R +w "$TMPDIR" && rm -fr "$TMPDIR"' EXIT

            export NUGET_HTTP_CACHE_PATH=''${NUGET_HTTP_CACHE_PATH-~/.local/share/NuGet/v3-cache}

            HOME=$TMPDIR/home
            mkdir "$HOME"

            cd "$TMPDIR"

            NIX_BUILD_SHELL=${lib.escapeShellArg runtimeShell} ${nix}/bin/nix-shell \
              --pure --keep NUGET_HTTP_CACHE_PATH --run 'source '${lib.escapeShellArg innerScript}' '"''${depsFile@Q}" "${drvPath}"
          '';
      };
  }
)
