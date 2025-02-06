{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  kicad,
  xdotool,
  libxslt,
  imagemagick,
  xvfbwrapper,
  psutil,
}:
buildPythonPackage rec {
  pname = "kiauto";
  version = "2.3.3";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "INTI-CMNB";
    repo = "KiAuto";
    tag = "v${version}";
    hash = "sha256-ZmKpf31oS60jGmaPUaF/WmZk9kyBeOGb2PMZ2OtQjf0=";
  };

  build-system = [ setuptools ];

  buildInputs = [
    kicad
    xdotool
    imagemagick
    libxslt
  ];

  dependencies = [
    psutil
    xvfbwrapper
  ];

  doCheck = false;

  pythonImportsCheck = [ "kiauto" ];

  meta = {
    description = "KiCad automation scripts.";
    homepage = "https://github.com/INTI-CMNB/KiAuto";
    changelog = "https://github.com/INTI-CMNB/KiAuto/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
