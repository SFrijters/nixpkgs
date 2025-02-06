{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  kiauto
}:
buildPythonPackage rec {
  pname = "kidiff";
  version = "2.5.6";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "INTI-CMNB";
    repo = "KiDiff";
    tag = "v${version}";
    hash = "sha256-DD21VLs5HlZovtaeCfPvEAry8dfkaG+wPSSI3bqWPIs=";
  };

  build-system = [ setuptools ];

  dependencies = [
    kiauto
  ];

  meta = {
    description = "Generates a PDF file showing the changes between two KiCad PCB or SCH files.";
    homepage = "https://github.com/INTI-CMNB/KiDiff";
    changelog = "https://github.com/INTI-CMNB/KiDiff/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
