import ./make-test-python.nix ({ pkgs, lib, ...}:

{
  name = "mono";
  meta = with lib.maintainers; {
    maintainers = [ corngood ];
  };

  nodes.machine = { pkgs, ... }: {
    imports = [ ../modules/profiles/minimal.nix ];
    boot.kernelPackages = pkgs.linuxPackages_latest;

    environment.systemPackages = [
      pkgs.mono

      (pkgs.writeScriptBin "test_mono" ''
        for (( i=0; i<1000; ++i))
        do
            mono $(dirname $(type -p mono))/../lib/mono/4.5/secutil.exe || exit 1
        done
      '')
    ];

  };

  testScript =
    ''
      start_all()

      with subtest("Test mono"):
          machine.succeed("test_mono")
    '';
})
