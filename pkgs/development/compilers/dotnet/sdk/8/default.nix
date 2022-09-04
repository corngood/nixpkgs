{ callPackage
}: callPackage ../stage1.nix {
  releaseManifest = ./release.json;
  hash = "sha256-pLtgOuFacpKpsltspY5Eza0ePcKjPcuM/TROAIh+fbI=";
  prepDepsFile = ./prep-deps.nix;
  buildDepsFile = ./build-deps.nix;
  bootstrapSdk =
    { stdenvNoCC
    , dotnetCorePackages
    , fetchurl
    }: dotnetCorePackages.sdk_8_0.overrideAttrs (old: {
    passthru = old.passthru or {} // {
      artifacts = stdenvNoCC.mkDerivation rec {
        name = "Private.SourceBuilt.Artifacts.8.0.100-rc.2.23502.1.centos.8-x64";

        src = fetchurl {
          url = "https://dotnetcli.azureedge.net/source-built-artifacts/assets/${name}.tar.gz";
          sha256 = "sha256-laCGu9UhXLnMKhGa7ADIU+Gr7S1LR77WpTP81wNeeRg=";
        };

        dontUnpack = true;

        installPhase = ''
          mkdir -p $out
          cp ${src} $out/${src.name}
        '';
      };
    };
  });
}
