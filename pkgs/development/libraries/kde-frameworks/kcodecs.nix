{
  mkDerivation,
  extra-cmake-modules,
  qtbase,
  qttools,
  gperf,
}:

mkDerivation {
  pname = "kcodecs";
  nativeBuildInputs = [
    extra-cmake-modules
    gperf
  ];
  buildInputs = [
    qttools
  ];
  propagatedBuildInputs = [ qtbase ];
  outputs = [
    "out"
    "dev"
  ];
}
