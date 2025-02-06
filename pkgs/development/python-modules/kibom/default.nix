{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  xlsxwriter,
}:
buildPythonPackage rec {
  pname = "kibom";
  version = "1.9.1-2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "INTI-CMNB";
    repo = "KiBoM";
    tag = "v${version}";
    hash = "sha256-DwQwsp1nFvtqrUdAM6w/X7rK9fwRyX09WHzmyda7mhQ=";
  };

  build-system = [ setuptools ];

  dependencies = [
    xlsxwriter
  ];

  # doCheck = false;

  pythonImportsCheck = [ "kibom" ];

  meta = {
    description = "Configurable BOM (Bill of Materials) generation tool for KiCad EDA";
    homepage = "https://github.com/INTI-CMNB/KiBoM";
    changelog = "https://github.com/INTI-CMNB/KiBoM/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
