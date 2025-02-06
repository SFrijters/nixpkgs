{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  wxpython,
  versionCheckHook,
}:
buildPythonPackage rec {
  pname = "interactive-html-bom";
  version = "2.9.0-2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "INTI-CMNB";
    repo = "InteractiveHtmlBom";
    tag = "v${version}";
    hash = "sha256-kWhaFyz5RkJz7cnVQ458gDfRkj/52tPsYba/WPFDzBo=";
  };

  build-system = [ setuptools ];

  # nativeBuildInputs = [
  #   versionCheckHook
  # ];

  # versionCheckProgram = "${placeholder "out"}/bin/generate_interactive_bom.py";

  dependencies = [
    wxpython
  ];

  meta = {
    description = "Configurable BOM (Bill of Materials) generation tool for KiCad EDA";
    homepage = "https://github.com/INTI-CMNB/KiBoM";
    changelog = "https://github.com/INTI-CMNB/KiBoM/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.sfrijters ];
    mainProgram = "generate_interactive_bom.py";
  };
}
