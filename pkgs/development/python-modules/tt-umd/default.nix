{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  distro,
  elasticsearch,
  psutil,
  pyyaml,
  rich,
  textual,
  requests,
  tomli,
  tqdm,
  pydantic,
  setuptools-scm,

  scikit-build-core,
  cmake,
  cpm-cmake,
  yaml-cpp,
  fmt,
  nanobench,
}:
buildPythonPackage rec {
  pname = "tt-umd";
  version = "0.9.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tenstorrent";
    repo = "tt-umd";
    tag = "v${version}";
    hash = "sha256-B/Hj5m75pVvJLOWw26A3QZn848ym/63AxxWiWqfzUTU=";
  };

  postPatch = ''
    install -D ${cpm-cmake}/share/cpm/CPM.cmake cmake/
  '';

  build-system = [
    setuptools
    setuptools-scm
  ];

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    yaml-cpp
    fmt
    nanobench
  ];

  dependencies = [
    scikit-build-core
    # distro
    # elasticsearch
    # psutil
    # pyyaml
    # rich
    # textual
    # requests
    # tomli
    # tqdm
    # pydantic
  ];

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeBool "CPM_USE_LOCAL_PACKAGES" true)
  ];

  meta = {
    description = "User Mode Driver for tenstorrent";
    homepage = "https://github.com/tenstorrent/tt-umd";
    maintainers = with lib.maintainers; [ RossComputerGuy ];
    license = with lib.licenses; [ asl20 ];
  };
}
