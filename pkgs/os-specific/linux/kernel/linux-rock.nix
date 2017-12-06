{ stdenv, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

with stdenv.lib;

let
  localVersion = "-kfd";
  version = "4.11.0${localVersion}";
  sha256 = "1x23kk7m3xpvlgd63y77xp9xklhss5dixs4hw3ypb88wxkb02m18";
in
import ./generic.nix (args // {
  inherit version;

  src = fetchFromGitHub {
    inherit sha256;
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "bd5536a8fd36b2ad5037712e58c7808fc8b5a377";
  };

  extraConfig = ''
    DRM_AMD_DC y
    LOCALVERSION ${localVersion}
  '';
} // (args.argsOverride or {}))
