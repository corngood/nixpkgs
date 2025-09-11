let
  nixpkgs = (import ./. { });
  system = nixpkgs.pkgsCross.x86_64-cygwin.bash;
in
nixpkgs.callPackage nixos/lib/make-system-tarball.nix {
  contents = [
  ];

  storeContents = [
    {
      object = system;
      symlink = "none";
    }
  ];
}
