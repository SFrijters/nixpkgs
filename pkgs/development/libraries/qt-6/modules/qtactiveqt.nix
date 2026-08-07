{
  lib,
  stdenv,
  qtModule,
  qtbase,
  qtdeclarative,
  qtshadertools,
  pkgsBuildBuild,
}:

qtModule {
  pname = "qtactiveqt";
  propagatedBuildInputs = [
    qtbase
    # qtdeclarative
    # qtshadertools
  ];

  broken = !lib.platforms.windows;

  # # Conditional is required to prevent infinite recursion during a cross build
  # cmakeFlags =
  #   lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
  #     "-DQt6CanvasPainterTools_DIR=${pkgsBuildBuild.qt6.qtcanvaspainter}/lib/cmake/Qt6CanvasPainterTools"
  #   ]
  #   ++ [
  #     "-DQt6ShaderToolsTools_DIR=${pkgsBuildBuild.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  #     "-DQt6QuickTools_DIR=${pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
  #   ];
}
