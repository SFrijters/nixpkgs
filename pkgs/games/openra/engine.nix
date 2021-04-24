/*  The package defintion for an OpenRA engine.
    It shares code with `mod.nix` by what is defined in `common.nix`.
    Similar to `mod.nix` it is a generic package definition,
    in order to make it easy to define multiple variants of the OpenRA engine.
    For each mod provided by the engine, a wrapper script is created,
    matching the naming convention used by `mod.nix`.
    This package could be seen as providing a set of in-tree mods,
    while the `mod.nix` pacakges provide a single out-of-tree mod.
*/
{ lib, stdenv, fetchurl
, packageAttrs
, patchEngine
, wrapLaunchGame
, engine
}:

with lib;

stdenv.mkDerivation (recursiveUpdate packageAttrs rec {
  name = "${pname}-${version}";
  pname = "openra";
  version = "1.0.0.0";
  # version = "1.0.0.0${engine.version}";

  src = engine.src;

  postPatch = patchEngine "." version;

  # nugetDeps = linkFarmFromDrvs "${pname}-nuget-deps" (import ./deps.nix {
  #   fetchNuGet = { name, version, sha256 }: fetchurl {
  #     name = "nuget-${name}-${version}.nupkg";
  #     url = "https://www.nuget.org/api/v2/package/${name}/${version}";
  #     inherit sha256;
  #   };
  # });

  deps = import ./deps.nix { inherit fetchurl; };

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_NOLOGO=1

    # nuget sources Add -Name nixos -Source "$PWD/nixos"
    # # nuget init "$nugetDeps" "$PWD/nixos"

    # # fixme: https://github.com/NuGet/Home/issues/4413
    # mkdir -p $HOME/.nuget/NuGet
    # cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet

    # dotnet restore --source "$PWD/nixos" OpenRA.sln

    # disable default-source so nuget does not try to download from online-repo
    nuget sources Disable -Name "nuget.org"
    # add all dependencies to a source called 'nixos'
    for package in ${toString deps}; do
      nuget add $package -Source nixos
    done
    dotnet restore --source nixos OpenRA.sln
    dotnet build --no-restore -c Release OpenRA.sln

    make version VERSION=${escapeShellArg version}

    runHook postConfigure
  '';

  buildFlags = [ "DEBUG=false" "all" "man-page" ];

  checkTarget = "nunit test";

  installTargets = [
    "install"
    "install-linux-icons"
    "install-linux-desktop"
    "install-linux-appdata"
    "install-linux-mime"
    "install-man-page"
  ];

  postInstall = ''
    ${wrapLaunchGame ""}

    ${concatStrings (map (mod: ''
      makeWrapper $out/bin/openra $out/bin/openra-${mod} --add-flags Game.Mod=${mod}
    '') engine.mods)}
  '';

  meta = {
    inherit (engine) description homepage;
  };
})
