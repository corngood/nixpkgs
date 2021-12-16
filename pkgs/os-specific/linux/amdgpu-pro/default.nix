{ lib, stdenv, fetchurl, elfutils, libelf, xz
, xorg, patchelf, openssl, libdrm, udev
, libxcb, libxshmfence, epoxy, perl, zlib
, ncurses, expat, libffi, libselinux
, libsOnly ? false, kernel ? null
}:

assert (!libsOnly) -> kernel != null;

with lib;

let

  kernelDir = if libsOnly then null else kernel.dev;

  bitness = if stdenv.is64bit then "64" else "32";

  libArch =
    if stdenv.hostPlatform.system == "i686-linux" then
      "i386-linux-gnu"
    else if stdenv.hostPlatform.system == "x86_64-linux" then
      "x86_64-linux-gnu"
    else throw "amdgpu-pro is Linux only. Sorry. The build was stopped.";

  ncurses5 = ncurses.override { abiVersion = "5"; };

in stdenv.mkDerivation rec {

  version = "21.30";
  pname = "amdgpu-pro";
  build = "${version}-1290604";

  outputs = [ "out" ] ++ optionals (!libsOnly) [ "fw" "kmod" ];

  name = pname + "-" + version + (optionalString (!libsOnly) "-${kernelDir.version}");

  src = fetchurl {
    url = "https://drivers.amd.com/drivers/linux/amdgpu-pro-${build}-ubuntu-20.04.tar.xz";
    sha256 = "sha256-WECqxjo2WLP3kMWeVyJgYufkvHTzwGaj57yeMGXiQ4I=";
    curlOpts = "--referer https://www.amd.com/en/support/kb/release-notes/rn-amdgpu-unified-linux-21-30";
  };

  hardeningDisable = [ "pic" "format" ];

  postUnpack = ''
    mkdir root
    pushd $sourceRoot
    for deb in *_all.deb *_i386.deb '' + optionalString stdenv.is64bit "*_amd64.deb" + ''; do echo $deb; ar p $deb data.tar.xz | tar -C ../root -xJ; done
    popd
    sourceRoot=root
  '';

  postPatch = ''
    pushd usr/src/amdgpu-*
    patchShebangs amd/dkms/*.sh
    substituteInPlace amd/dkms/pre-build.sh --replace "./configure" "./configure --with-linux=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source --with-linux-obj=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    popd
  '';

  preConfigure = ''
    pushd usr/src/amdgpu-*
    makeFlags="$makeFlags M=$(pwd)"
    amd/dkms/pre-build.sh ${kernel.version}
    popd
  '';

  postBuild = ''
    pushd usr/src/amdgpu-*
    # HACK: turn compression back on
    find -name \*.ko -exec xz -0 {} \;
    popd
  '';

  makeFlags = "-C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build modules";

  depLibPath = makeLibraryPath [
    stdenv.cc.cc.lib xorg.libXext xorg.libX11 xorg.libXdamage xorg.libXfixes zlib
    xorg.libXxf86vm libxcb libxshmfence epoxy openssl libdrm elfutils udev ncurses5
    expat libffi libselinux
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    cp -r usr/lib/${libArch} $out/lib
    cp -r usr/share $out/share

    mkdir -p $out/opt/amdgpu{,-pro}
    cp -r opt/amdgpu-pro/lib/${libArch} $out/opt/amdgpu-pro/lib
    cp -r opt/amdgpu/lib/${libArch} $out/opt/amdgpu/lib

    pushd $out/lib
    ln -s ../opt/amdgpu-pro/lib/libGL.so* .
    ln -s ../opt/amdgpu-pro/lib/libEGL.so* .
    popd

  '' + optionalString (!libsOnly) ''
    mkdir -p $out/etc
    pushd etc
    cp -r modprobe.d udev amd $out/etc
    popd
    cp -r lib/udev/rules.d/* $out/etc/udev/rules.d
    cp -r opt/amdgpu/lib/xorg $out/lib/xorg
    cp -r opt/amdgpu-pro/lib/xorg/* $out/lib/xorg
    cp -r opt/amdgpu/share $out/opt/amdgpu/share

    mkdir -p $fw/lib
    cp -r usr/src/amdgpu-*/firmware $fw/lib/firmware

    pushd usr/src/amdgpu-*
    find -name \*.ko.xz -exec install -Dm444 {} $kmod/lib/modules/${kernel.modDirVersion}/kernel/drivers/gpu/drm/{} \;
    popd
  '' + ''

    runHook postInstall
  '';

  preFixup = ''
    perl -pi -e 's:/opt/amdgpu/lib/x86_64-linux-gnu/dri\0:/run/opengl-driver/lib/dri\0\0\0\0\0\0\0\0\0\0\0:g' $out/opt/amdgpu/lib/libEGL.so.1.0.0
    perl -pi -e 's:/opt/amdgpu/lib/x86_64-linux-gnu/dri\0:/run/opengl-driver/lib/dri\0\0\0\0\0\0\0\0\0\0\0:g' $out/opt/amdgpu/lib/libgbm.so.1.0.0
    perl -pi -e 's:/opt/amdgpu/lib/x86_64-linux-gnu/dri\0:/run/opengl-driver/lib/dri\0\0\0\0\0\0\0\0\0\0\0:g' $out/opt/amdgpu/lib/libGL.so.1.2.0

    perl -pi -e 's:/usr/lib/x86_64-linux-gnu/dri\0:/run/opengl-driver/lib/dri\0\0\0\0:g' $out/opt/amdgpu-pro/lib/libEGL.so.1
    perl -pi -e 's:/usr/lib/x86_64-linux-gnu/dri\::/run/opengl-driver/lib/dri\0\0\0\0:g' $out/lib/xorg/modules/extensions/libglx.so
    perl -pi -e 's:/usr/lib/x86_64-linux-gnu/dri\::/run/opengl-driver/lib/dri\0\0\0\0:g' $out/opt/amdgpu-pro/lib/libGL.so.1.2
    find $out -type f -exec perl -pi -e 's:/opt/amdgpu-pro/:/run/amdgpu-pro/:g' {} \;
    find $out -type f -exec perl -pi -e 's:/opt/amdgpu/:/run/amdgpu/:g' {} \;
  '';

  # we'll just set the full rpath on everything to avoid having to track down dlopen problems
  postFixup = ''
    libPath="$out/opt/amdgpu/lib:$out/opt/amdgpu-pro/lib:$depLibPath"
    for lib in `find "$out" -name '*.so*' -type f`; do
      patchelf --set-rpath "$libPath" "$lib"
    done
  '';

  buildInputs = [
    libelf
    patchelf
    perl
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "AMDGPU-PRO drivers";
    homepage =  "http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Beta-Driver-for-Vulkan-Release-Notes.aspx";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ corngood ];
    # Copied from the nvidia default.nix to prevent a store collision.
    priority = 4;
  };
}
