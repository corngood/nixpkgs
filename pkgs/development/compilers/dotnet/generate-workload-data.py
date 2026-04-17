#!/usr/bin/env python3
"""
Generate workload pack data (Nix expressions) from SDK workload manifests.

Usage:
  python3 generate-workload-data.py <major.minor>

Example:
  python3 generate-workload-data.py 9.0

The script builds the binary SDK for the given .NET version from nixpkgs
(using the current checkout) and reads its bundled workload manifests.

Generates data for all non-abstract workloads, resolved for all supported
RIDs (linux-x64, linux-arm64, osx-x64, osx-arm64).
"""

import base64
import json
import json5
import hashlib
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path


def load_manifest(manifest_path: Path) -> dict:
    with open(manifest_path, 'r') as file:
        manifest = json5.load(file)
    return manifest

RID_GRAPH = {
    "linux-x64": ["linux", "unix", "any"],
    "linux-arm64": ["linux", "unix", "any"],
    "linux-musl-x64": ["linux-musl", "linux", "unix", "any"],
    "linux-musl-arm64": ["linux-musl", "linux", "unix", "any"],
    "osx-x64": ["osx", "unix", "any"],
    "osx-arm64": ["osx", "unix", "any"],
    "win-x64": ["win", "any"],
    "win-arm64": ["win", "any"],
    "win-x86": ["win", "any"],
}


def resolve_rid(alias_to: dict, host_rid: str) -> str | None:
    """Resolve an alias-to mapping for a host RID using the RID graph."""
    if host_rid in alias_to:
        return alias_to[host_rid]
    for parent_rid in RID_GRAPH.get(host_rid, []):
        if parent_rid in alias_to:
            return alias_to[parent_rid]
    return None


def resolve_workload_packs(
    workload_id: str,
    workloads: dict,
    packs: dict,
    host_rid: str,
    visited: set | None = None,
) -> list[dict]:
    """Resolve all packs for a workload, following extends transitively."""
    if visited is None:
        visited = set()
    if workload_id in visited:
        return []
    visited.add(workload_id)

    wdef = workloads.get(workload_id)
    if wdef is None:
        print(f"WARNING: workload {workload_id!r} not found", file=sys.stderr)
        return []

    # Check platform restriction
    platforms = wdef.get("platforms", [])
    if platforms and host_rid not in platforms:
        return []

    result = []

    # Resolve extends first
    for base_id in wdef.get("extends", []):
        result.extend(
            resolve_workload_packs(base_id, workloads, packs, host_rid, visited)
        )

    # Then this workload's own packs
    for pack_id in wdef.get("packs", []):
        pdef = packs.get(pack_id)
        if pdef is None:
            print(f"WARNING: pack {pack_id!r} not found", file=sys.stderr)
            continue

        version = pdef["version"]
        kind = pdef.get("kind", "library")

        alias_to = pdef.get("alias-to")
        if alias_to:
            nuget_id = resolve_rid(alias_to, host_rid)
            if nuget_id is None:
                # Pack not available on this platform
                continue
        else:
            nuget_id = pack_id

        result.append(
            {
                "packId": pack_id,
                "nugetId": nuget_id,
                "version": version,
                "kind": kind.lower(),
            }
        )

    # Deduplicate by nugetId+version
    seen = set()
    deduped = []
    for p in result:
        key = (p["nugetId"], p["version"])
        if key not in seen:
            seen.add(key)
            deduped.append(p)

    return deduped


class Fetcher:
    def __init__(self):
        with urllib.request.urlopen("https://api.nuget.org/v3/index.json") as resp:
            index = json.load(resp)
        resources = { resource['@type']: resource['@id'] for resource in index['resources'] }
        self.package_base_url = resources['PackageBaseAddress/3.0.0']

    def fetch_nuget_hash(self, nuget_id: str, version: str) -> str:
        """Fetch a NuGet package and compute its SRI hash. Returns None on 404."""
        lid = nuget_id.lower()
        lver = version.lower()
        url = f"{self.package_base_url}{lid}/{lver}/{lid}.{lver}.nupkg"
        req = urllib.request.Request(
            url, headers={"User-Agent": "nixpkgs-workload-gen/1.0"}, method="HEAD"
        )
        with urllib.request.urlopen(req) as resp:
            sha512=resp.getheader('x-ms-meta-sha512')
        sri = "sha512-" + sha512
        return sri


def generate_nix(
    manifest: dict,
    fetcher: Fetcher,
):
    """Generate a Nix expression for workload packs across all supported RIDs."""
    # Resolve for all RIDs
    # all_resolved = {}  # (rid, wid) -> [pack]
    # for rid in SUPPORTED_RIDS:
    #     for wid in workload_ids:
    #         resolved = resolve_workload_packs(wid, workloads, packs, rid)
    #         all_resolved[(rid, wid)] = resolved

    # Collect all unique packs across all RIDs
    # unique_packs = {}
    # for pack_list in all_resolved.values():
    #     for p in pack_list:
    #         key = (p["nugetId"], p["version"])
    #         if key not in unique_packs:
    #             unique_packs[key] = p

    # Fetch hashes
    # for key, p in sorted(unique_packs.items()):
    #     p["hash"] = fetcher.fetch_nuget_hash(p["nugetId"], p["version"])
    # Remove packs that couldn't be fetched (404)
    # missing = {k for k, p in unique_packs.items() if p["hash"] is None}
    # if missing:
    #     print(f"  Skipping {len(missing)} unavailable packs", file=sys.stderr)
    #     unique_packs = {
    #         k: p for k, p in unique_packs.items() if p["hash"] is not None
    #     }
    #     # Also remove from per-RID mappings
    #     for key, pack_list in all_resolved.items():
    #         all_resolved[key] = [
    #             p for p in pack_list if (p["nugetId"], p["version"]) not in missing
    #         ]

    # Generate Nix
    print("# Auto-generated workload pack data. Do not edit.")
    print("{ mkPack, mkWorkload }:")
    print("let")
    print("  packs = {")
    for id, pack in manifest['packs'].items():
        version = pack['version']
        print(f"    \"{id}\" = mkPack {{")
        if 'alias-to' in pack:
            print( "      alias-to = {")
            for rid, pname in pack['alias-to'].items():
                print(f"        {rid} = {{")
                print(f"          pname = \"{pname}\";")
                print(f"          hash = \"{fetcher.fetch_nuget_hash(pname, version)}\";")
                print( "        };")
            print( "      };")
        else:
            print(f"        pname = \"{pname}\";")
            print(f"        hash = \"{fetcher.fetch_nuget_hash(id, version)}\";")
        print("    };")
    print("  };")
    print("")
    print("  workloads = {")
    for id, workload in manifest['workloads'].items():
        print(f"    {id} = mkWorkload {{")
        print( "      packs = [")
        for pack in workload['packs']:
            print(f"        packs.\"{pack}\"")
        print( "      ];")
        if 'extends' in workload:
            print( "      extends = [")
            for workload in workload['extends']:
                print(f"        workloads.{workload}")
            print( "      ];")
        print( "    };")
    print("  };")
    print("in")
    print("workloads")


def resolve_sdk_path(dotnet_version: str) -> Path:
    """Build the binary SDK from nixpkgs and return its store path."""
    # Map version to the nixpkgs attribute for the binary (unwrapped) SDK.
    # We use the _1xx-bin variant because it has the baseline manifests.
    major, minor = dotnet_version.split(".")
    attr = f"dotnetCorePackages.sdk_{major}_{minor}_1xx-bin.unwrapped"

    nixpkgs_dir = (
        Path(__file__).resolve().parents[4]
    )  # pkgs/development/compilers/dotnet -> repo root
    print(f"Building {attr} from {nixpkgs_dir}...", file=sys.stderr)

    result = subprocess.run(
        ["nix-build", str(nixpkgs_dir), "-A", attr, "--no-out-link"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        raise RuntimeError(f"Failed to build {attr}")

    store_path = result.stdout.strip()
    print(f"SDK path: {store_path}", file=sys.stderr)
    return Path(store_path)


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    # dotnet_version = sys.argv[1]
    manifest_path = Path(sys.argv[1]);

    # sdk_path = resolve_sdk_path(dotnet_version)

    # Detect SDK band
    # sdk_manifests = sdk_path / "share" / "dotnet" / "sdk-manifests"
    # bands = sorted(
    #     [d.name for d in sdk_manifests.iterdir() if d.is_dir()], reverse=True
    # )
    # band = bands[0]  # Use the latest band
    # print(f"Using SDK band: {band}", file=sys.stderr)

    manifest = load_manifest(manifest_path)

    generate_nix(
        manifest,
        Fetcher()
    )


if __name__ == "__main__":
    main()
