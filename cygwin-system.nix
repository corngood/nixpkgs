{ system, self }:
import nixos/lib/eval-config.nix {

  inherit system;

  baseModules = [
    ./nixos/modules/config/nix-flakes.nix
    ./nixos/modules/config/nix.nix
    ./nixos/modules/config/system-path.nix
    ./nixos/modules/misc/nixpkgs-flake.nix
    ./nixos/modules/misc/nixpkgs.nix
    ./nixos/modules/security/ca.nix
    ./nixos/modules/system/etc/etc.nix

    ./cygwin-tarball.nix
    ./cygwin-custom.nix
  ];

  modules = [
    (
      { lib, pkgs, config, ... }:
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

          environment.corePackages = with pkgs; lib.mkForce [
            bash
            coreutils
            openssh
            rsync
            curl
            config.nix.package
          ];
          environment.defaultPackages = lib.mkForce [ ];

          nixpkgs.crossSystem.system = "x86_64-cygwin";

          nix = {
            enable = true;
            useSandbox = false;
            settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            package = pkgs.nixVersions.git;
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
