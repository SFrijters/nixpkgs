{
  qtModule,
  qtbase,
  qtquick3d,
  qtshadertools,
}:

qtModule {
  pname = "qtcanvaspainter";
  propagatedBuildInputs = [
    qtbase
    qtquick3d
    qtshadertools
  ];
}
