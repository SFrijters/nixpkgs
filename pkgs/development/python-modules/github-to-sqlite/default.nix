{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  isPy3k,
  pytestCheckHook,
  pyyaml,
  requests,
  requests-mock,
  sqlite-utils,
}:

buildPythonPackage rec {
  pname = "github-to-sqlite";
  version = "2.9";
  format = "setuptools";
  disabled = !isPy3k;

  src = fetchFromGitHub {
    owner = "dogsheep";
    repo = "github-to-sqlite";
    rev = version;
    hash = "sha256-KwLaaZxBBzRhiBv4p8Imb5XI1hyka9rmr/rxA6wDc7Q=";
  };

  propagatedBuildInputs = [
    sqlite-utils
    pyyaml
    requests
  ];

  nativeCheckInputs = [
    pytestCheckHook
    requests-mock
  ];

  disabledTests = [ "test_scrape_dependents" ];

  meta = with lib; {
    description = "Save data from GitHub to a SQLite database";
    mainProgram = "github-to-sqlite";
    homepage = "https://github.com/dogsheep/github-to-sqlite";
    license = licenses.asl20;
    maintainers = with maintainers; [ sarcasticadmin ];
  };
}
