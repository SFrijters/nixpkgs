{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchpatch,
  substituteAll,
  cmake,
  wrapQtAppsHook,
  qtbase,
  qcoro,
  qtwebsockets,
  qttools,
  qtquick3d,
  qtmultimedia,
  qtimageformats,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "brickstore";
  version = "2023.8.1";

  src = fetchFromGitHub {
    owner = "rgriebl";
    repo = "brickstore";
    rev = "refs/tags/v${finalAttrs.version}";
    sha256 = "sha256-lBK84ERtbokSKja+v2tLoTMFuBYKTxjETlL3d3wJZ+I=";
  };

  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
  ];

  buildInputs = [
    qtbase
    qcoro
    qtwebsockets
    qttools
    qtquick3d
    qtmultimedia
    qtimageformats
  ];

  doCheck = false;

  patches = [
    # Fix build error, remove after next release
    (fetchpatch {
      url = "https://github.com/rgriebl/brickstore/commit/58fa83aeed99944a3e6c720726fb8e5cf270790c.patch";
      sha256 = "sha256-o6rf1JMxlCxmykevcW05jUevKXjMeYwSkJfgtpNgGhI=";
    })
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
