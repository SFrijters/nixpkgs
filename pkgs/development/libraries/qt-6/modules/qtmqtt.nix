{
  qtModule,
  qtbase,
  qtdeclarative,
  qtwebsockets,
  pkgsBuildBuild,
}:

qtModule {
  pname = "qtmqtt";

  propagatedBuildInputs = [
    qtbase
    qtdeclarative
    qtwebsockets
  ];

  cmakeFlags = [
    "-DQt6QuickTools_DIR=${pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
  ];
}
