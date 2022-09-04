{ stdenv
, lib
, callPackage
, pkgsBuildHost

, releaseManifest
, hash
, prepDepsFile
, buildDepsFile
, bootstrapSdk
}@args:

let
  mkPackages = callPackage ./packages.nix;
  mkVMR = callPackage ./vmr.nix;

  stage0 = pkgsBuildHost.callPackage ./stage0.nix args;

  vmr = (mkVMR {
    inherit releaseManifest hash;
    dotnetSdk = stage0.sdk;
  }).overrideAttrs (old: {
    patches =
      old.patches or []
      # error : Did not find PDBs for the following SDK files:
      # sdk/8.0.100/Containers/tasks/net8.0/Valleysoft.DockerCredsProvider.dll
      ++ lib.optional stdenv.isDarwin
        ./allow-missing-pdbs.patch;
    prepFlags = [
      "--no-artifacts"
    ] ++ old.prepFlags;
    buildFlags = [
      "--with-packages" stage0.sdk.artifacts
    ] ++ old.buildFlags;
    passthru = old.passthru or {} // {
      inherit (stage0.sdk) fetch-deps;
    };
  });

in mkPackages { inherit vmr; }
