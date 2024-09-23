{ callPackage
, dotnetCorePackages
}: callPackage ../dotnet.nix {
  releaseManifestFile = ./release.json;
  releaseInfoFile = ./release-info.json;
  depsFile = ./deps.nix;
  bootstrapSdk = dotnetCorePackages.sdk_8_0_1xx-bin;
}
