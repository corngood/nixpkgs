{
  mkNugetDeps,
  nugetPackages,
  lib,
}:
let
  inherit (lib)
    concatMap
    elem
    foldl'
    length
    listToAttrs
    nameValuePair
    unique
    ;

  addDependencies =
    acc: packages: dependencies:
    let
      deps = map (x: packages.${x}) (unique (concatMap (x: map (x: x.id) x.packages) dependencies));
    in
    foldl' (
      acc: e:
      assert (length acc < 1000);
      if elem e acc then
        acc
      else
        addDependencies (acc ++ [ e ]) packages e.nugetDependencies
    ) acc deps;

  findDependencies = addDependencies [ ];

  mkPackage =
    {
      id,
      version,
      hash,
      dependencies,
    }:
    nameValuePair id (
      (mkNugetDeps rec {
        name = "${id}-${version}";
        nugetDeps =
          { fetchNuGet }:
          [
            (fetchNuGet {
              pname = id;
              inherit version hash;
            })
          ];
      }).overrideAttrs
        (old: {
          passthru.nugetDependencies = dependencies;
          passthru.allDependencies = findDependencies nugetPackages dependencies;
        })
    );

in
listToAttrs (map mkPackage (builtins.fromJSON (builtins.readFile ./nuget-packages.json)))
// {
  inherit findDependencies;
}
