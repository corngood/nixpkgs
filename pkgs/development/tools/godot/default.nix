{ callPackage, nix-update-script }:
let
  mkGodot =
    versionPrefix:
    let
      attrs = import ./${versionPrefix};
    in
    rec {
      godot = (callPackage ./common.nix attrs).overrideAttrs (old: {
        passthru = old.passthru or { } // {
          updateScript = [
            ./update.sh
            versionPrefix
            (builtins.unsafeGetAttrPos "version" attrs).file
          ];
        };
      });
      godot-mono = godot.override {
        withMono = true;
      };
    };
in
rec {
  godot3 = callPackage ./3 { };
  godot3-export-templates = callPackage ./3/export-templates.nix { };
  godot3-headless = callPackage ./3/headless.nix { };
  godot3-debug-server = callPackage ./3/debug-server.nix { };
  godot3-server = callPackage ./3/server.nix { };
  godot3-mono = callPackage ./3/mono { };
  godot3-mono-export-templates = callPackage ./3/mono/export-templates.nix { };
  godot3-mono-headless = callPackage ./3/mono/headless.nix { };
  godot3-mono-debug-server = callPackage ./3/mono/debug-server.nix { };
  godot3-mono-server = callPackage ./3/mono/server.nix { };

  godot_4_3 = mkGodot "4.3";
  godot_4_4 = mkGodot "4.4";
  godot_4 = godot_4_3;
  godot = godot_4;
}
