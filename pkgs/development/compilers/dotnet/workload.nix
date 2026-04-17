{ lib }:
let
  base = 8.0/sdk-manifests;

  workloadset = lib.importJSON (
    base + /8.0.100/workloadsets/8.0.419-baseline.26113.1/baseline.workloadset.json
  );

  manifests = lib.mapAttrs (
    id: versions:
    let
      parts = lib.splitString "/" versions;
      version = lib.elemAt parts 0;
    in
    {
      ${version} = lib.importJSON (
        base
        + "/${lib.toLower (lib.elemAt parts 1)}/${lib.toLower id}/${lib.toLower version}/WorkloadManifest.json"
      );
    }
  ) workloadset;

  workloads = lib.foldlAttrs (l: _: v: l ++ map (x: x.workloads) (lib.attrValues v)) [] manifests;

in
workloads
