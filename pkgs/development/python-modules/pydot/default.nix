{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  substituteAll,
  graphviz,
  pytestCheckHook,
  chardet,
  parameterized,
  pythonOlder,
  pyparsing,
}:

buildPythonPackage rec {
  pname = "pydot";
  version = "3.0.1";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-4Yz38ofEl9d7U2o9IKRihFaP6jkHdt+s5uq73xsbXvw=";
  };

  build-system = [ setuptools ];

  dependencies = [ pyparsing ];

  nativeCheckInputs = [
    chardet
    parameterized
    pytestCheckHook
  ];

  patches = [
    (substituteAll {
      src = ./hardcode-graphviz-path.patch;
      inherit graphviz;
    })
  ];

  pythonImportsCheck = [ "pydot" ];

  meta = {
    description = "Allows to create both directed and non directed graphs from Python";
    homepage = "https://github.com/erocarrera/pydot";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
