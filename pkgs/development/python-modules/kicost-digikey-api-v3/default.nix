{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  inflection,
  requests,
  urllib3,
  six,
  certifi,
  pyopenssl,
  tldextract,
  python-dateutil,
}:
buildPythonPackage rec {
  pname = "kicost-digikey-api-v3";
  version = "0.1.3";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "set-soft";
    repo = "kicost-digikey-api-v3";
    tag = "v${version}";
    hash = "sha256-O4bYvf8EnAlcgJ/fqYEuo2+37Q6lTdmlSrmaD2Cl/q8=";
  };

  build-system = [ setuptools ];

  dependencies = [
    inflection
    requests
    urllib3
    six
    certifi
    setuptools
    pyopenssl
    tldextract
    python-dateutil
  ];

  # doCheck = false;

  # pythonImportsCheck = [ "kibom" ];

  meta = {
    description = "Configurable BOM (Bill of Materials) generation tool for KiCad EDA";
    homepage = "https://github.com/set-soft/kicost-digikey-api-v3";
    changelog = "https://github.com/set-soft/kicost-digikey-api-v3/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
