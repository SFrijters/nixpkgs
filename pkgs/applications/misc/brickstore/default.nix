{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchpatch,
  substituteAll,
  cmake,
  pkg-config,
  wrapQtAppsHook,
  qtbase,
  qcoro,
  qtwebsockets,
  qttools,
  qtquick3d,
  qtmultimedia,
  qtimageformats,
  libsecret,
  libgcrypt,
  libgpg-error,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "brickstore";
  version = "2023.11.2";

  src = fetchFromGitHub {
    owner = "rgriebl";
    repo = "brickstore";
    rev = "refs/tags/v${finalAttrs.version}";
    sha256 = "sha256-GmyX5SyZA9qeousAqdwq5xSOV6e1xQzkvnTjgQfbpHQ=";
  };

  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
    pkg-config
  ];

  buildInputs = [
    qtbase
    qcoro
    qtwebsockets
    qttools
    qtquick3d
    qtmultimedia
    qtimageformats
    libsecret
    libgcrypt
    libgpg-error
  ];

  doCheck = false;

  patches = [
    # Do not fetch dependencies, use the nix store instead
    (substituteAll {
      src = ./dont_fetch_dependencies.patch;
      qcoro_src = qcoro.src;
    })
  ];

  meta = with lib; {
    homepage = "https://www.brickstore.dev/";
    changelog = "https://github.com/rgriebl/brickstore/releases/tag/v${finalAttrs.version}";
    description = "A BrickLink offline management tool";
    mainProgram = "brickstore";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ sfrijters ];
  };
})
