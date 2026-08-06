{
  lib,
  stdenv,
  qtModule,
  qtbase,
  qtdeclarative,
  cups,
  llvmPackages,
  pkgsBuildBuild,
  # clang-based c++ parser for qdoc and lupdate
  withClang ? false,
}:

qtModule {
  pname = "qttools";

  postPatch = ''
    substituteInPlace \
      src/qdoc/catch/CMakeLists.txt \
      src/qdoc/catch_generators/CMakeLists.txt \
      src/qdoc/catch_conversions/CMakeLists.txt \
      --replace ''\'''${CMAKE_INSTALL_INCLUDEDIR}' "$out/include"
  '';

  env.NIX_CFLAGS_COMPILE = toString [
    "-DNIX_OUTPUT_OUT=\"${placeholder "out"}\""
  ];

  buildInputs = lib.optionals withClang [
    llvmPackages.libclang
    llvmPackages.llvm
  ];

  propagatedBuildInputs = [
    qtbase
    qtdeclarative
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cups
  ];

  # Conditional is required to prevent infinite recursion during a cross build
  cmakeFlags = lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    "-DQt6LinguistTools_DIR=${pkgsBuildBuild.qt6.qttools}/lib/cmake/Qt6LinguistTools"
    "-DQt6ToolsTools_DIR=${pkgsBuildBuild.qt6.qttools}/lib/cmake/Qt6ToolsTools"
  ]
  ++ lib.optionals (qtdeclarative != null) [
    "-DQt6QuickTools_DIR=${pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6QmlTools_DIR=${pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
  ]
  ++ lib.optionals withClang [
    "-DFEATURE_clang=ON"
  ];

  postInstall = ''
    mkdir -p "$dev"
    ln -s "$out/bin" "$dev/bin"
  '';
}
