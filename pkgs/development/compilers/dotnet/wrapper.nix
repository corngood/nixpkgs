{
  stdenv,
  stdenvNoCC,
  lib,
  writeText,
  testers,
  runCommand,
  runCommandWith,
  darwin,
  expect,
  curl,
  installShellFiles,
  callPackage,
  zlib,
  swiftPackages,
  icu,
  lndir,
  replaceVars,
  nugetPackageHook,
  xmlstarlet,
  pkgs,
}:
type: unwrapped:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "${unwrapped.pname}-wrapped";
  inherit (unwrapped) version;

  meta = {
    description = "${unwrapped.meta.description or "dotnet"} (wrapper)";
    mainProgram = "dotnet";
    inherit (unwrapped.meta)
      homepage
      license
      maintainers
      platforms
      ;
  };

  src = unwrapped;
  dontUnpack = true;

  setupHooks = [
    ./dotnet-setup-hook.sh
  ]
  ++ lib.optional (type == "sdk") (
    replaceVars ./dotnet-sdk-setup-hook.sh {
      inherit lndir xmlstarlet;
    }
  );

  propagatedSandboxProfile = toString unwrapped.__propagatedSandboxProfile;

  propagatedBuildInputs = lib.optional (type == "sdk") nugetPackageHook;

  nativeBuildInputs = [ installShellFiles ];

  outputs = [ "out" ] ++ lib.optional (unwrapped ? man) "man";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/bin "$out"/share
    ln -s "$src"/bin/* "$out"/bin
    ln -s "$src"/share/dotnet "$out"/share
    runHook postInstall
  '';

  postInstall = ''
    # completions snippets taken from https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
    installShellCompletion --cmd dotnet \
      --bash ${./completions/dotnet.bash} \
      --zsh ${./completions/dotnet.zsh} \
      --fish ${./completions/dotnet.fish}
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$(mktemp -d) $out/bin/dotnet --info
    runHook postInstallCheck
  '';

  postFixup = lib.optionalString (unwrapped ? man) ''
    ln -s ${unwrapped.man} "$man"
  '';

  passthru = unwrapped.passthru // {
    inherit unwrapped;
    tests =
      unwrapped.passthru.tests or { }
      // {
        version = testers.testVersion {
          package = finalAttrs.finalPackage;
          command = "HOME=$(mktemp -d) dotnet " + (if type == "sdk" then "--version" else "--info");
        };
      }
      // lib.optionalAttrs (type == "sdk") (
        (pkgs.appendOverlays [
          (self: super: {
            dotnet-sdk = finalAttrs.finalPackage;
            dotnet-runtime = finalAttrs.finalPackage.runtime;
          })
        ]).callPackage
          ../../../test/dotnet/default.nix
          { }
      );
  };
})
