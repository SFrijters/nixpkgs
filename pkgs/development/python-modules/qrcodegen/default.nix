{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
}:
buildPythonPackage rec {
  pname = "qrcodegen";
  version = "1.8.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-gtth9QZba6bXYGEVuUE6va/fP+nCgQBHEA0I7O0Ybp4=";
    extension = "zip";
  };

  meta = with lib; {
    homepage = "https://pypi.org/project/qrcodegen/";
    license = with licenses; [ mit ];
  };
}
