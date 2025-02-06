{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  xlsxwriter,
  beautifulsoup4,
  lxml,
  tqdm,
  requests,
  validators,
  wxpython,
  colorama,
  pyyaml,
  kicost-digikey-api-v3,
  distutils,
}:
buildPythonPackage rec {
  pname = "kicost";
  version = "1.1.19";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "hildogjr";
    repo = "KiCost";
    tag = "v${version}";
    hash = "sha256-XGHNf9kvyeL06r46ta11gPJpOMDt77AAi9/MST1DgNI=";
  };

  build-system = [ setuptools ];

  dependencies = [
    beautifulsoup4
    lxml
    xlsxwriter
    tqdm
    requests
    validators
    wxpython
    colorama
    pyyaml
    kicost-digikey-api-v3
    distutils
  ];

  # doCheck = false;

  pythonImportsCheck = [ "kicost" ];

  meta = {
    description = "Configurable BOM (Bill of Materials) generation tool for KiCad EDA";
    homepage = "https://github.com/INTI-CMNB/KiBoM";
    changelog = "https://github.com/INTI-CMNB/KiBoM/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
