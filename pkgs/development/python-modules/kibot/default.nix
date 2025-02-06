{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  kiauto,
  kibom,
  kidiff,
  pyyaml,
  xlsxwriter,
  colorama,
  requests,
  qrcodegen,
  markdown2,
  numpy,
  lark,
  kicad,
  ghostscript,
  imagemagick,
  pandoc,
  xvfb-run,
  python3,
  librsvg,
  makeFontsConf,
  lxml,
  xvfbwrapper,
  kicost,
  blender,
  kikit,
  interactive-html-bom,
  rar,
}:
buildPythonPackage rec {
  pname = "kibot";
  version = "1.8.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "INTI-CMNB";
    repo = "KiBot";
    tag = "v${version}";
    hash = "sha256-r2LpLYUzh7b8UxF938IUAxzpP2EmHBRYcCjtT6j2qJM=";
  };

  build-system = [ setuptools ];

  dependencies = [
    kiauto
    kibom
    kicost
    kidiff
    kikit
    pyyaml
    xlsxwriter
    colorama
    requests
    qrcodegen
    markdown2
    numpy
    lark
    lxml
    xvfbwrapper
  ];

  doCheck = false;

  postPatch = ''
    sed -i 's/Helvetica/Arial/' src/kibot-check

    substituteInPlace src/kibot-check \
      --replace-fail "(cmd[0], e.returncode)" "(cmd, e.returncode)" \
      --replace-fail "cmd.insert(0, 'python3')" "pass"
  '';

  postInstall = ''
    # echo ${kicad}
    for program in kibot kibot-check kiplot; do
      wrapProgram $out/bin/$program \
        --prefix PATH : ${lib.makeBinPath [ kicad ghostscript imagemagick pandoc xvfb-run librsvg blender interactive-html-bom rar ]} \
        --prefix PYTHONPATH : ${kicad}/${python3.sitePackages}
        # --set FONTCONFIG_FILE ${makeFontsConf { fontDirectories = [ "${ghostscript}/share/ghostscript/fonts" ]; }};
    done
  '';

  pythonImportsCheck = [ "kibot" ];

  meta = {
    description = "Helps you to generate the fabrication and documentation files for your KiCad projects easily, repeatable, and most of all, scriptably.";
    homepage = "https://github.com/INTI-CMNB/KiBot";
    changelog = "https://github.com/INTI-CMNB/KiBot/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.sfrijters ];
  };
}
