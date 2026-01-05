{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (pkgs)
    bash
    buildEnv
    coreutils
    runCommand
    writeShellScript
    ;

  nix = config.nix.package;

  sw = buildEnv {
    name = "cygwin-root";

    paths = config.environment.systemPackages;

    nativeBuildInputs = [
      ../../../../pkgs/build-support/setup-hooks/make-symlinks-relative.sh
    ];
  };

  activate = writeShellScript "activate" ''
    (
      export PATH=${
        lib.makeBinPath [
          coreutils
          nix
        ]
      }:/bin
      mkdir -p /nix/var/nix/gcroots
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system
      mkdir -p /run
      ln -sfn '${lib.getExe bash}' /bin/sh
      ln -sfn '@out@' /run/current-system
      ln -sfn /run/current-system/etc /etc
      if [[ -f /nix-path-registration ]]; then
        nix-store --load-db < /nix-path-registration
        rm /nix-path-registration
      fi
    )
  '';

in
{
  options = {
    system.cygwin.toplevel = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  imports = [
    ../../../modules/profiles/minimal.nix
  ];

  config = {
    boot = {
      bcache.enable = false;
      initrd = {
        supportedFilesystems = [ ];
      };
      kernel.sysctl = lib.mkForce { };
      loader.grub.enable = false;
      modprobeConfig.enable = false;
      supportedFilesystems = [ ];
    };

    console.enable = false;

    fonts.fontconfig.enable = false;

    # the default requires glibcLocales
    i18n.supportedLocales = [ ];

    networking = {
      dhcpcd.enable = false;
      firewall.enable = false;
      resolvconf.enable = false;
    };

    programs = {
      fuse.enable = false;
      less.enable = lib.mkForce false;
      nano.enable = false;
      ssh.systemd-ssh-proxy.enable = false;
    };

    security = {
      pam.enable = false;
      shadow.enable = false;
      sudo.enable = false;
    };

    services = {
      lvm.enable = false;
      udev.enable = false;
    };

    system = {
      disableInstallerTools = true;
      # this is needed because tasks/filesystems.nix unconditionally adds
      # dosfstools, and tasks/filesystems/ext adds e2fsprogs
      fsPackages = lib.mkForce [ ];
      # these match the cygwin defaults when "file" is prepended
      nssDatabases = {
        passwd = [ "db" ];
        group = [ "db" ];
      };
    };

    systemd = {
      enable = false;
      coredump.enable = false;
    };

    users = {
      users = lib.mkForce { };
      groups = lib.mkForce { };
    };

    environment.corePackages =
      with pkgs;
      lib.mkForce [
        bash
        coreutils
        openssh
        curl
        config.nix.package
      ];
    environment.defaultPackages = lib.mkForce [ ];

    nixpkgs.buildPlatform = lib.mkDefault builtins.currentSystem;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-cygwin";

    nix = {
      settings = {
        sandbox = false;
        ignored-acls = "user.$kernel.purge.esbcache";
      };
      package = pkgs.nixVersions.git;
    };

    system.cygwin.toplevel = runCommand "cygwin-system" { } ''
      mkdir "$out"
      ln -sr "${sw}" "$out"/sw
      cp "${activate}" "$out"/activate
      substituteInPlace $out/activate --subst-var-by out "$out"
      ln -sr "${config.system.build.etc}"/etc $out/etc
    '';
  };
}
