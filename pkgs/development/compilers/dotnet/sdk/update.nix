{ stdenvNoCC
, lib
, writeScript
, nix
, curl
, cacert
, jq

, hash
, releaseManifest
}:

let
  manifestJson = lib.importJSON releaseManifest;
  inherit (manifestJson) release channel;

  pkg = stdenvNoCC.mkDerivation {
    name = "update-dotnet-vmr-env";

    nativeBuildInputs = [
      curl
      cacert
      jq
    ];
  };

  drv = builtins.unsafeDiscardOutputDependency pkg.drvPath;

in writeScript "update-dotnet-vmr.sh" ''
#! /usr/bin/env nix-shell
#! nix-shell -i bash --pure ${drv}

query=$(cat <<EOF
  map(
    select(
      .prerelease == false and
      .draft == false and
      (.name | startswith(".NET ${channel}")))) |
  first | (
    .name,
    (.assets |
      .[] |
      select(.name == "release.json") |
      .browser_download_url)
  )
EOF
)

(
  # curl -fsL https://api.github.com/repos/dotnet/dotnet/releases | \
  cat releases |
\
  jq -r "$query" \
) | (
  read name
  read releaseUrl

  if [[ "$name" == ".NET ${release}" ]]; then
    >&2 echo "release is already $name"
    exit
  fi
  echo curl -fsL "$releaseUrl" -o ${toString releaseManifest}
)
''
