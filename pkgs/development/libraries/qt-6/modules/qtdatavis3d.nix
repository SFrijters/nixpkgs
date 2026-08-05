{
  qtModule,
  qtbase,
  qtdeclarative,
  qtquick3d,
}:

qtModule {
  pname = "qtdatavis3d";
  propagatedBuildInputs = [
    qtbase
    qtdeclarative
    qtquick3d
  ];
}
