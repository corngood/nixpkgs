{ stdenv, fetchurl, bash, git, cmake, python3, libX11 }:

stdenv.mkDerivation rec {
  version = "1.0.26.0";
  name = "libvulkan-${version}";

  src = fetchurl {
    url = "https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers/archive/sdk-${version}.tar.gz";
    sha256 = "04k3m68nab6w4hpssw0dl3x3s1c6dc990ngrmn3j2lzcrkvm18s0";
  };

  enableParallelBuilding = true;

  buildInputs = [ bash git cmake python3 libX11 ];

  # needed for git https
  SSL_CERT_FILE = /etc/ssl/certs/ca-bundle.crt;

  preConfigure = "bash update_external_sources.sh";

  installPhase = ''
    mkdir -p $out/lib $out/bin
    cp -r ../include $out/
    cp loader/libvulkan.so* $out/lib
    cp demos/vulkaninfo $out/bin/
    mkdir -p $out/lib $out/etc/explicit_layer.d
    cp layers/*.so $out/lib/
    cp layers/*.json $out/etc/explicit_layer.d/
    sed -i "s:\\./lib:$out/lib/lib:g" "$out/etc/"**/*.json
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers;
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
