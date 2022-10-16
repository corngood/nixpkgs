{}:

let
  pkgs = import ./../../default.nix {};

  inherit (pkgs) lib;

  /* Remove duplicate elements from the list based on some extracted value. O(n^2) complexity.
   */
  nubOn = f: list:
    if list == [] then
      []
    else
      let
        x = lib.head list;
        xs = lib.filter (p: f x != f p) (lib.drop 1 list);
      in
        [x] ++ nubOn f xs;

  /* Recursively find all packages (derivations) in `pkgs` matching `cond` predicate.

    Type: packagesWithPath :: AttrPath → (AttrPath → derivation → bool) → AttrSet → List<AttrSet{attrPath :: str; package :: derivation; }>
          AttrPath :: [str]

    The packages will be returned as a list of named pairs comprising of:
      - attrPath: stringified attribute path (based on `rootPath`)
      - package: corresponding derivation
   */
  packagesWithPath = rootPath: cond: pkgs:
    let
      packagesWithPathInner = path: pathContent:
        let
          result = builtins.tryEval pathContent;

          dedupResults = lst: nubOn ({ package, attrPath }: package) (lib.concatLists lst);
        in
          if result.success then
            let
              evaluatedPathContent = result.value;
            in
              if lib.isDerivation evaluatedPathContent then
                lib.optional (cond path evaluatedPathContent) { attrPath = lib.concatStringsSep "." path; package = evaluatedPathContent; }
              else if lib.isAttrs evaluatedPathContent then
                # If user explicitly points to an attrSet or it is marked for recursion, we recur.
                if path == rootPath || evaluatedPathContent.recurseForDerivations or false || evaluatedPathContent.recurseForRelease or false then
                  dedupResults (lib.mapAttrsToList (name: elem: packagesWithPathInner (path ++ [name]) elem) evaluatedPathContent)
                else []
              else []
          else [];
    in
      packagesWithPathInner rootPath pkgs;

  /* Recursively find all packages (derivations) in `pkgs` matching `cond` predicate.
   */
  packagesWith = packagesWithPath [];

  packages =
    packagesWith (path: pkgs: pkgs ? fetch-deps) pkgs;

  helpText = ''
    Please run:

        % nix-shell maintainers/scripts/update-dotnet-lockfiles.nix
  '';

  fetchScripts = map (p: p.package.fetch-deps) packages;

in pkgs.stdenv.mkDerivation {
  name = "nixpkgs-update-script";
  buildCommand = ''
    echo ""
    echo "----------------------------------------------------------------"
    echo ""
    echo "Not possible to update packages using \`nix-build\`"
    echo ""
    echo "${helpText}"
    echo "----------------------------------------------------------------"
    exit 1
  '';
  shellHook = ''
    unset shellHook # do not contaminate nested shells
    set -e
    for x in $fetchScripts; do
      $x
    done
    exit
  '';
  inherit fetchScripts;
}
