{ lib
, stdenv
, buildDotnetModule
, fetchFromGitHub
, dotnetCorePackages
, openssl
, mono
}:

buildDotnetModule rec {
  pname = "bluebrick";
  # version = "unstable-2021-05-18";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "Lswbanban";
    repo = "BlueBrick";
    rev = "4d467ec20f0b1c06136ce4752f4bd6e00880e3e1";
    hash = "sha512-/t8uID6GTvUnnX0w/XF4U6/ShI5pJwIRE2KAnfLUP/M1Lc+jOWTpmBpa7hnl9tdOKfewOLNSPuedqhOe9menLQ==";
  };

  nugetDeps = ./deps.nix;

  projectFile = "BlueBrick/BlueBrick.csproj";
  executables = [ "BlueBrick" ];


  patchPhase = ''
    runHook prePatch

    substituteInPlace BlueBrick/BlueBrick.csproj \
      --replace "<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>" "<TargetFrameworkVersion>v6.0</TargetFrameworkVersion>"
    runHook postPatch
  '';

  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;

  dotnetInstallFlags = [ "-p:TargetFramework=net6.0" ];

  # runtimeDeps = [ openssl ];

  # doCheck = !(stdenv.isDarwin && stdenv.isAarch64); # mono is not available on aarch64-darwin
  # nativeCheckInputs = [ mono ];
  # testProjectFile = "src/Jackett.Test/Jackett.Test.csproj";

  # postFixup = ''
  #   # For compatibility
  #   ln -s $out/bin/jackett $out/bin/Jackett || :
  #   ln -s $out/bin/Jackett $out/bin/jackett || :
  # '';
  # passthru.updateScript = ./updater.sh;

  meta = with lib; {
    description = "LEGO® Layout Editor by Alban Nanty";
    homepage = "https://bluebrick.lswproject.com/";
    changelog = "https://bluebrick.lswproject.com/download.html";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ edwtjo nyanloutre purcell ];
  };
}
