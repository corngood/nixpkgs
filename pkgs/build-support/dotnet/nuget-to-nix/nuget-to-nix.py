#!@pythonInterpreter@

import sys
import os
import subprocess
import asyncio
import re
import json
import aiofiles
import aiohttp
import hashlib
from xml.etree import ElementTree

sources = []

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

async def get_lines(prog, *args):
    p = await asyncio.create_subprocess_exec(
        prog, *args,
        stdout=asyncio.subprocess.PIPE)
    stdout = p.stdout
    while True:
        line = await stdout.readline()
        if line == b'':
            break
        yield line.decode('utf-8')
    await p.wait()
    if p.returncode != 0:
        raise subprocess.CalledProcessError(p.returncode, prog)

async def get_sources():
    regex = re.compile('^E (.*)')
    async for line in get_lines(
        '@dotnet@/bin/dotnet', 'nuget', 'list', 'source', '--format', 'short'):
        if m := regex.match(line):
            yield m.group(1)

async def get_index(session, source):
    response = await session.get(source)
    index = next(
        x['@id']
        for x in (await response.json())['resources']
        if x['@type'] == 'PackageBaseAddress/3.0.0')
    eprint(f'index {index} for {source}')
    return (index, source)

async def get_indices(session):
    return [
        asyncio.create_task(get_index(session, source))
        async for source in get_sources()]

async def get_packages(packagedir):
    for package in sorted(os.listdir(packagedir)):
        if package == '.tools':
            continue
        path = os.path.join(packagedir, package)
        for version in sorted(os.listdir(path)):
            yield package, version

async def sha256_hex_to_base32(hexdigest):
    async for line in get_lines(
        '@nix@/bin/nix-hash', '--type', 'sha256', '--to-base32', hexdigest):
        return line.strip()

async def get_packageid(package, version, packagedir):
    nuspec = os.path.join(packagedir, package, version, f'{package}.nuspec')
    async with aiofiles.open(nuspec) as f:
        xml = ElementTree.fromstring(await f.read())
        return xml.find('./{*}metadata/{*}id').text


async def get_packagedef(package, version, packagedir, indices, session):
    pid = await get_packageid(package, version, packagedir)
    metadata = os.path.join(packagedir, package, version, '.nupkg.metadata')
    async with aiofiles.open(metadata) as f:
        used_source = json.loads(await f.read())['source']
    eprint(f'used {used_source}')
    async def from_index(index):
        (index, source) = await index
        url=f'{index}{package}/{version}/{package}.{version}.nupkg'
        hash = hashlib.sha256()
        if source == used_source:
            nupkg = os.path.join(packagedir, package, version, f'{package}.{version}.nupkg')
            eprint(f'found {package}-{version} at {nupkg}')
            async with aiofiles.open(nupkg, mode='rb') as f:
                while chunk := await f.read(64 * 1024):
                    hash.update(chunk)
        else:
            async with session.get(url) as response:
                match response.status:
                    case 200:
                        eprint(f'found {package}-{version} at {url}')
                        async for chunk in response.content.iter_chunked(64 * 1024):
                            hash.update(chunk)
                    case 404:
                        return None
                    case _:
                        raise Exception(f'{url} response status {response.status}')
        if source == 'https://api.nuget.org/v3/index.json':
            url = None
        return (
            hash.hexdigest(),
            url)
    # tasks = [
    #     asyncio.create_task(from_index(index))
    #     for index in indices]
    # for task in tasks:
    #     pdef = await task
    for index in indices:
        pdef = await from_index(index)
        if pdef is not None:
            digest, url = pdef
            return (pid, version, await sha256_hex_to_base32(digest), url)
    raise Exception(f'{package} {version} not found in any sources')

async def write_deps(packagedir):
    packages = get_packages(packagedir)

    async with aiohttp.ClientSession() as session:
        indices = await get_indices(session)
        # def get_pdef(t):
        #     p, v = t
        #     return get_packagedef(p, v, packagedir, indices, session)
        # for pdef in await asyncio.gather(*list(map(get_pdef, packages))):
        #     print(pdef)
        tasks = [
            asyncio.create_task(get_packagedef(p, v, packagedir, indices, session))
            async for p, v in packages]
        sys.stdout.write('{ fetchNuGet }: [\n')
        for task in tasks:
            id, version, sha256, url = await task
            sys.stdout.write(f'  (fetchNuGet {{ pname = "{id}"; version = "{version}"; sha256 = "{sha256}";');
            if url is not None:
                sys.stdout.write(f' url = "{url}";')
            sys.stdout.write(' })\n')
        sys.stdout.write(']\n')

packagedir = sys.argv[1]
asyncio.run(write_deps(packagedir))

'''
declare -a remote_sources

for index in "${sources[@]}"; do
  if [[ ! -e "$index" ]]; then
    remote_sources+=("$index")
  fi
done

declare -A base_addresses

for index in "${remote_sources[@]}"; do
  base_addresses[$index]=$(
    curl --compressed --netrc -fsL "$index" | \
      jq -r '.resources[] | select(."@type" == "PackageBaseAddress/3.0.0")."@id"')
done

echo "{ fetchNuGet }: ["

cd "$pkgs"

declare -a packages
packages=(*/*)

for x in "${packages[@]}"
do
    echo FOO $x
done

echo P $packages

for source in "${remote_sources[@]}"
do
    base="${base_addresses[$source]}$package/$version/$package.$version.nupkg"
    for x in "${packages[@]}"
    do
        url="$base$package/$version/$package.$version.nupkg"
        echo $url
    done
done

exit 1

    for source in "${remote_sources[@]}"; do

      url="${base_addresses[$source]}$package/$version/$package.$version.nupkg"
      if [[ "$source" == "$used_source" ]]; then
        sha256="$(nix-hash --type sha256 --flat --base32 "$version/$package.$version".nupkg)"
        found=true
        break
      else
        if sha256=$(nix-prefetch-url "$url" 2>"$tmp"/error); then
          # If multiple remote sources are enabled, nuget will try them all
          # concurrently and use the one that responds first. We always use the
          # first source that has the package.
          echo "$package $version is available at $url, but was restored from $used_source" 1>&2
          found=true
          break
        else
          if ! grep -q 'HTTP error 404' "$tmp/error"; then
            cat "$tmp/error" 1>&2
            exit 1
          fi
        fi
      fi
    done

    if ! ${found-false}; then
      echo "couldn't find $package $version" >&2
      exit 1
    fi

    if [[ "$source" != https://api.nuget.org/v3/index.json ]]; then
      echo "  (fetchNuGet { pname = \"$id\"; version = \"$version\"; sha256 = \"$sha256\"; url = \"$url\"; })"
    else
      echo "  (fetchNuGet { pname = \"$id\"; version = \"$version\"; sha256 = \"$sha256\"; })"
    fi
  done
  cd ..
done

for package in *; do
  cd "$package"
  for version in *; do
    id=$(xq -r .package.metadata.id "$version/$package".nuspec)

    if grep -qxF "$id.$version.nupkg" "$excluded_list"; then
      continue
    fi

    used_source="$(jq -r '.source' "$version"/.nupkg.metadata)"
    # This means a local source was used, which is likely in /nix/store/, so we
    # don't need it in the lock file.
    if [[ ! -v base_addresses[$used_source] ]]; then
       continue
    fi
    for source in "${remote_sources[@]}"; do
      url="${base_addresses[$source]}$package/$version/$package.$version.nupkg"
      if [[ "$source" == "$used_source" ]]; then
        sha256="$(nix-hash --type sha256 --flat --base32 "$version/$package.$version".nupkg)"
        found=true
        break
      else
        if sha256=$(nix-prefetch-url "$url" 2>"$tmp"/error); then
          # If multiple remote sources are enabled, nuget will try them all
          # concurrently and use the one that responds first. We always use the
          # first source that has the package.
          echo "$package $version is available at $url, but was restored from $used_source" 1>&2
          found=true
          break
        else
          if ! grep -q 'HTTP error 404' "$tmp/error"; then
            cat "$tmp/error" 1>&2
            exit 1
          fi
        fi
      fi
    done

    if ! ${found-false}; then
      echo "couldn't find $package $version" >&2
      exit 1
    fi

    if [[ "$source" != https://api.nuget.org/v3/index.json ]]; then
      echo "  (fetchNuGet { pname = \"$id\"; version = \"$version\"; sha256 = \"$sha256\"; url = \"$url\"; })"
    else
      echo "  (fetchNuGet { pname = \"$id\"; version = \"$version\"; sha256 = \"$sha256\"; })"
    fi
  done
  cd ..
done

cat << EOL
]
EOL
'''
