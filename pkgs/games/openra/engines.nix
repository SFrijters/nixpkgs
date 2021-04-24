{ buildOpenRAEngine, fetchFromGitHub, extraPostFetch }:

let
  buildUpstreamOpenRAEngine = { version, rev, sha256 }: name: (buildOpenRAEngine {
    inherit version;
    description = "Open-source re-implementation of Westwood Studios' 2D Command and Conquer games";
    homepage = "https://www.openra.net/";
    mods = [ "cnc" "d2k" "ra" "ts" ];
    src = fetchFromGitHub {
      owner = "OpenRA";
      repo = "OpenRA" ;
      inherit rev sha256 extraPostFetch;
    };
  } name).overrideAttrs (origAttrs: {
    postInstall = ''
      ${origAttrs.postInstall}
      cp -r mods/ts $out/lib/openra/mods/
      cp mods/ts/icon.png $(mkdirp $out/share/pixmaps)/openra-ts.png
      ( cd $out/share/applications; sed -e 's/Dawn/Sun/g' -e 's/cnc/ts/g' openra-cnc.desktop > openra-ts.desktop )
    '';
  });

in {
  release = name: (buildUpstreamOpenRAEngine rec {
    version = "20210321";
    rev = "${name}-${version}";
    sha256 = "sha256-PUmwPAv3Y93wswsel5NBfh6FwmSKZE1ewDRjore7DYY=";
  } name);

  playtest = name: (buildUpstreamOpenRAEngine rec {
    version = "20210131";
    rev = "${name}-${version}";
    sha256 = "1vqvfk2p2lpk3m0d3rpvj34i8cmk3mfc7w4cn4llqd9zp4kk9py0";
  } name);

  bleed = buildUpstreamOpenRAEngine {
    version = "f1a9a51";
    rev = "f1a9a5180d572e2ab00f0336cfaaf5104c77ce4b";
    sha256 = "0f1fpf37ms8d7fhlh3rjzsxsk9w23iyi3phs2i7g561292d5rk30";
  };
}
