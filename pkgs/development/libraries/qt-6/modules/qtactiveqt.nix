{
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
  ];
}
