{ symlinkJoin, fetch-nupkg }:
{ name, nugetDeps, sourceFile ? null }:
symlinkJoin {
  name = "${name}-nuget-deps";
  paths = nugetDeps {
    fetchNuGet = fetch-nupkg;
  };
} // {
  inherit sourceFile;
}
