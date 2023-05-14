import ./make-test-python.nix ({ pkgs, lib, ...}:

{
  name = "mono";
  meta = with lib.maintainers; {
    maintainers = [ corngood ];
  };

  nodes.machine = { pkgs, ... }: {
    imports = [ ../modules/profiles/minimal.nix ];
    boot.kernelPackages = pkgs.linuxPackages_testing;

    environment.systemPackages = [
      pkgs.mono

      (pkgs.runCommandCC "test-crash" {} ''
        gcc -o test-crash ${../../test.c};
        mkdir -p $out/bin
        cp test-crash $out/bin
      '')
    ];

  };

  testScript =
    ''
      start_all()

      with subtest("Test crash"):
          machine.succeed("test-crash")
    '';
})
