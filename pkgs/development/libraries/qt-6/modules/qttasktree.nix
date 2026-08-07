{
  qtModule,
  qtbase,
}:

qtModule {
  pname = "qttasktree";
  propagatedBuildInputs = [
    qtbase
  ];
}
