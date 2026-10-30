{
  lib,
  stdenv,
  python3,
}:
let
  evalString = ''
    stdenv.buildPlatform: ${stdenv.buildPlatform.system} ${if stdenv.buildPlatform.isStatic then "static" else "shared"}"
    stdenv.hostPlatform: ${stdenv.hostPlatform.system} ${if stdenv.hostPlatform.isStatic then "static" else "shared"}"
    availableOn host: ${if (lib.meta.availableOn stdenv.hostPlatform python3) then "yes" else "no"}"
    availableOn build: ${if (lib.meta.availableOn stdenv.hostPlatform python3) then "yes" else "no"}"
    broken: ${if (python3.meta.broken or false) then "yes" else "no"}"
  '';
in
stdenv.mkDerivation {
  name = "broken-available-test";

  dontUnpack = true;

  dontBuild = true;

  installPhase = lib.trace evalString ''
    echo foo > $out
  '';
}
