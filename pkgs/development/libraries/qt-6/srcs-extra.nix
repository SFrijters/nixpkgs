{ fetchFromGitHub }:

{
  qtmqtt =
    let
      version = "6.11.1";
    in
    {
      inherit version;
      src = fetchFromGitHub {
        owner = "qt";
        repo = "qtmqtt";
        tag = "v${version}";
        hash = "sha256-GWaF4iCPtATL1mJkPHVY0rom8R2FMNWGahE3KWBlfV8=";
      };
    };
}
