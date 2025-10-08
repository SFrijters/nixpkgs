{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  dtc,
}:

stdenv.mkDerivation {
  pname = "raspi-utils";
  version = "0-unstable-2025-10-02";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "9f61b87db715fe9729305e242de8412d8db4153c";
    hash = "sha256-LAEAjxb6+lQKo2VUknkuZa5sK37k6SjF+imj/7qyOe4=";
  };

  nativeBuildInputs = [
    cmake
    dtc
  ];

  cmakeFlags = [
    # -DARM64=ON disables all targets that only build on 32-bit ARM; this allows
    # the package to build on aarch64 and other architectures.
    # May be unnecessary
    (lib.cmakeBool "ARM64" stdenv.hostPlatform.isAarch64)
    (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}")
  ];

  meta = {
    description = "Collection of scripts and simple applications for interfacing with Raspberry Pi hardware";
    homepage = "https://github.com/raspberrypi/utils";
    license = lib.licenses.bsd3;
    platforms = [
      "armv6l-linux"
      "armv7l-linux"
      "aarch64-linux"
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [
      gigglesquid
    ];
  };
}
