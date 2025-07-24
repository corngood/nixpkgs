{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libxkbcommon,
  python3,
  runCommand,
  wprs,
}:
rustPlatform.buildRustPackage {
  pname = "wprs";
  version = "0-unstable-2025-06-13";

  src = fetchFromGitHub {
    owner = "wayland-transpositor";
    repo = "wprs";
    rev = "578e42ac3e74f83c33e43991b1322dfd9bf6d603";
    hash = "sha256-QWEVkM2mEz4E1ZK5ecTazsvyuwtrT6OAGCRmvw5TijE=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libxkbcommon
    (python3.withPackages (pp: with pp; [ psutil ]))
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-irZPb2S6TXf4r8IX/efk363UspWkJ5MlCLocoWMi30U=";

  preFixup = ''
    cp  wprs "$out/bin/wprs"
  '';

  passthru.tests.sanity = runCommand "wprs-sanity" { nativeBuildInputs = [ wprs ]; } ''
    ${wprs}/bin/wprs -h > /dev/null && touch $out
  '';

  meta = with lib; {
    description = "rootless remote desktop access for remote Wayland";
    license = licenses.asl20;
    maintainers = with maintainers; [ mksafavi ];
    platforms = [ "x86_64-linux" ]; # The aarch64-linux support is not implemented in upstream yet. Also, the darwin platform is not supported as it requires wayland.
    homepage = "https://github.com/wayland-transpositor/wprs";
    mainProgram = "wprs";
  };
}
