{ system, self }:
import nixos/lib/eval-config.nix {

  inherit system;

  baseModules = [
    ./nixos/modules/misc/nixpkgs.nix
    ./nixos/modules/security/ca.nix
    ./nixos/modules/system/etc/etc.nix
    ./nixos/modules/config/nix.nix
    ./nixos/modules/config/nix-flakes.nix
    ./nixos/modules/misc/nixpkgs-flake.nix

    ./cygwin-tarball.nix
  ];

  modules = [
    (
      { lib, ... }:
      {
        options = {
          nix = {
            channel.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            nixPath = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        };

        config = {

          nixpkgs.crossSystem.system = "x86_64-cygwin";

          nix = {
            enable = true;
            settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          };

          nixpkgs.flake = {
            source = self.outPath;
            setFlakeRegistry = true;
          };
        };
      }
    )
  ];
}
