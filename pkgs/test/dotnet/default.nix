{
  callPackage,
  curl,
  darwin,
  dotnet-runtime,
  dotnet-sdk,
  expect,
  lib,
  runCommand,
  stdenv,
  stdenvNoCC,
  swiftPackages,
  testers,
  zlib,
}:

let
  mkDotnetTest =
    {
      name,
      stdenv ? stdenvNoCC,
      template,
      lang ? null,
      usePackageSource ? false,
      build,
      buildInputs ? [ ],
      runtime ? dotnet-runtime,
      runInputs ? [ ],
      run ? null,
      runAllowNetworking ? false,
    }:
    let
      sdk = dotnet-sdk;
      built = stdenv.mkDerivation {
        name = "${sdk.name}-test-${name}";
        buildInputs = [ sdk ] ++ buildInputs ++ lib.optional usePackageSource sdk.packages;
        # make sure ICU works in a sandbox
        propagatedSandboxProfile = toString sdk.__propagatedSandboxProfile;
        unpackPhase =
          let
            unpackArgs = [
              template
            ]
            ++ lib.optionals (lang != null) [
              "-lang"
              lang
            ];
          in
          ''
            mkdir test
            cd test
            dotnet new ${lib.escapeShellArgs unpackArgs} -o . --no-restore
          '';
        buildPhase = build;
        dontPatchELF = true;
      };
    in
    # older SDKs don't include an embedded FSharp.Core package
    if lang == "F#" && lib.versionOlder sdk.version "6.0.400" then
      null
    else if run == null then
      built
    else
      runCommand "${built.name}-run"
        (
          {
            src = built;
            nativeBuildInputs = [ built ] ++ runInputs;
            passthru = {
              inherit built;
            };
          }
          // lib.optionalAttrs (stdenv.hostPlatform.isDarwin && runAllowNetworking) {
            sandboxProfile = ''
              (allow network-inbound (local ip))
              (allow mach-lookup (global-name "com.apple.FSEvents"))
            '';
            __darwinAllowLocalNetworking = true;
          }
        )
        (
          lib.optionalString (runtime != null) ''
            export DOTNET_ROOT=${runtime}/share/dotnet
          ''
          + run
        );

  mkConsoleTests =
    lang: suffix: output:
    let
      # Setting LANG to something other than 'C' forces the runtime to search
      # for ICU, which will be required in most user environments.
      checkConsoleOutput = command: ''
        output="$(LANG=C.UTF-8 ${command})"
        [[ "$output" =~ ${output} ]] && touch "$out"
      '';

      mkConsoleTest =
        { name, ... }@args:
        mkDotnetTest (
          args
          // {
            name = "console-${name}-${suffix}";
            template = "console";
            inherit lang;
          }
        );
    in
    lib.recurseIntoAttrs {
      run = mkConsoleTest {
        name = "run";
        build = checkConsoleOutput "dotnet run";
      };

      publish = mkConsoleTest {
        name = "publish";
        build = "dotnet publish -o $out/bin";
        run = checkConsoleOutput "$src/bin/test";
      };

      self-contained = mkConsoleTest {
        name = "self-contained";
        usePackageSource = true;
        build = "dotnet publish --use-current-runtime --sc -o $out";
        runtime = null;
        run = checkConsoleOutput "$src/test";
      };

      single-file = mkConsoleTest {
        name = "single-file";
        usePackageSource = true;
        build = "dotnet publish --use-current-runtime -p:PublishSingleFile=true -o $out/bin";
        runtime = null;
        run = checkConsoleOutput "$src/bin/test";
      };

      ready-to-run = mkConsoleTest {
        name = "ready-to-run";
        usePackageSource = true;
        build = "dotnet publish --use-current-runtime -p:PublishReadyToRun=true -o $out/bin";
        run = checkConsoleOutput "$src/bin/test";
      };
    }
    // lib.optionalAttrs dotnet-sdk.hasILCompiler {
      aot = mkConsoleTest {
        name = "aot";
        stdenv = if stdenv.hostPlatform.isDarwin then swiftPackages.stdenv else stdenv;
        usePackageSource = true;
        buildInputs = [
          zlib
        ]
        ++ lib.optional stdenv.hostPlatform.isDarwin [
          swiftPackages.swift
          darwin.ICU
        ];
        build = ''
          dotnet restore -p:PublishAot=true
          dotnet publish -p:PublishAot=true -o $out/bin
        '';
        runtime = null;
        run = checkConsoleOutput "$src/bin/test";
      };
    };

  mkWebTest =
    lang: suffix:
    mkDotnetTest {
      name = "web-${suffix}";
      template = "web";
      inherit lang;
      build = "dotnet publish -o $out/bin";
      runtime = dotnet-sdk.aspnetcore;
      runInputs = [
        expect
        curl
      ];
      run = ''
        expect <<"EOF"
          set status 1
          spawn $env(src)/bin/test
          proc abort { } { exit 2 }
          expect_before default abort
          expect -re {Now listening on: ([^\r]+)\r} {
            set url $expect_out(1,string)
          }
          expect "Application started. Press Ctrl+C to shut down."
          set output [exec curl -sSf $url]
          if {$output != "Hello World!"} {
            send_error "Unexpected output: $output\n"
            exit 1
          }
          send \x03
          expect_before timeout abort
          expect eof
          catch wait result
          exit [lindex $result 3]
        EOF
        touch $out
      '';
      runAllowNetworking = true;
    };
in
{
  console = lib.recurseIntoAttrs {
    # yes, older SDKs omit the comma
    cs = mkConsoleTests "C#" "cs" "Hello,?\\ World!";
    fs = mkConsoleTests "F#" "fs" "Hello\\ from\\ F#";
    vb = mkConsoleTests "VB" "vb" "Hello,?\\ World!";
  };

  web = lib.recurseIntoAttrs {
    cs = mkWebTest "C#" "cs";
    fs = mkWebTest "F#" "fs";
  };

  project-references = callPackage ./project-references { };
  use-dotnet-from-env = lib.recurseIntoAttrs (callPackage ./use-dotnet-from-env { });
  structured-attrs = lib.recurseIntoAttrs (callPackage ./structured-attrs { });
  final-attrs = lib.recurseIntoAttrs (callPackage ./final-attrs { });
  nuget-deps = lib.recurseIntoAttrs (callPackage ./nuget-deps { });
}
