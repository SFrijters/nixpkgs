{
  lib,
  buildPythonPackage,
  fetchPypi,
  unittestCheckHook,
  mock,
  sphinx-testing,
  sphinx,
  blockdiag,
}:

buildPythonPackage (finalAttrs: {
  pname = "sphinxcontrib-blockdiag";
  version = "3.0.0";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    sha256 = "aa49bf924516f5de8a479994c7be81e077df5599c9da2a082003d5b388e1d450";
  };

  buildInputs = [
    mock
    sphinx-testing
  ];
  propagatedBuildInputs = [
    sphinx
    blockdiag
  ];

  # Seems to look for files in the wrong dir
  doCheck = false;

  nativeCheckInputs = [ unittestCheckHook ];

  unittestFlags = [
    "--start-directory=tests"
  ];

  pythonNamespaces = [ "sphinxcontrib" ];

  meta = {
    description = "Sphinx blockdiag extension";
    homepage = "https://github.com/blockdiag/sphinxcontrib-blockdiag";
    maintainers = [ ];
    license = lib.licenses.bsd2;
  };
})
