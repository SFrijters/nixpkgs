# The wrapper script ensures variables like PKG_CONFIG_PATH and
# PKG_CONFIG_PATH_FOR_BUILD work properly.

{
  stdenvNoCC,
  lib,
  buildPackages,
  replaceVars,
  makeSetupHook,
  expand-response-params,
  pkg-config,
  baseBinName ? "pkg-config",
  propagateDoc ? pkg-config != null && pkg-config ? man,
  extraPackages ? [ ],
  extraBuildCommands ? "",
}:

let
  inherit (lib)
    attrByPath
    getBin
    optional
    optionalAttrs
    optionals
    optionalString
    replaceStrings
    ;

  stdenv = stdenvNoCC;
  inherit (stdenv) hostPlatform targetPlatform;

  # Prefix for binaries. Customarily ends with a dash separator.
  #
  # TODO(@Ericson2314) Make unconditional, or optional but always true by
  # default.
  targetPrefix = optionalString (targetPlatform != hostPlatform) (targetPlatform.config + "-");

  # See description in cc-wrapper.
  suffixSalt = replaceStrings [ "-" "." ] [ "_" "_" ] targetPlatform.config;

  wrapperName = "PKG_CONFIG_WRAPPER";
  wrapperBinName = "${targetPrefix}${baseBinName}";
in

stdenv.mkDerivation {
  pname = targetPrefix + pkg-config.pname + "-wrapper";
  inherit (pkg-config) version;

  enableParallelBuilding = true;

  preferLocalBuild = true;

  outputs = [ "out" ] ++ optionals propagateDoc ([ "man" ] ++ optional (pkg-config ? doc) "doc");

  passthru = {
    inherit
      targetPrefix
      suffixSalt
      pkg-config
      baseBinName
      wrapperName
      ;
  };

  strictDeps = true;
  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase =
    let
      wrapper = replaceVars ./pkg-config-wrapper.sh {
        inherit suffixSalt;
        out = placeholder "out";
        shell = getBin stdenvNoCC.shell + stdenvNoCC.shell.shellPath or "";
        prog = "${getBin pkg-config}/bin/${baseBinName}";
        addFlags = optionalString stdenv.targetPlatform.isStatic "--static";
      };
    in
  ''
    mkdir -p $out/bin $out/nix-support
    install -m555 -T ${wrapper} $out/bin/${wrapperBinName}
    echo $pkg-config > $out/nix-support/orig-pkg-config
  ''
  # symlink in share for autoconf to find macros

  # TODO(@Ericson2314): in the future just make the unwrapped pkg-config a
  # propagated dep once we can rely on downstream deps coming first in
  # search paths. (https://github.com/NixOS/nixpkgs/pull/31414 took a crack
  # at this.)
  + ''
    ln -s ${pkg-config}/share $out/share
  '';

  setupHooks = let
    roleHook = makeSetupHook rec {
      name = "pkg-config-role-hook";
      substitutions = {
        inherit
          name
          suffixSalt
          wrapperName
          ;
      };
    } ../setup-hooks/role.bash;
    setupHook = makeSetupHook {
      name = "pkgs-config-setup-hook";
      substitutions = {
        inherit
          targetPrefix
          baseBinName
        ;
      };
    } ./setup-hook.sh;
  in
    [
      "${roleHook}/nix-support/setup-hook"
      "${setupHook}/nix-support/setup-hook"
    ];

  postFixup = let
    addFlags = replaceVars ./add-flags.sh { inherit suffixSalt; };
    utils = replaceVars ../wrapper-common/utils.bash {
      inherit
        suffixSalt
        wrapperName
      ;
      inherit (targetPlatform) darwinMinVersion;
      expandResponseParams = "${expand-response-params}/bin/expand-response-params";
    };

  in
    ##
    ## User env support
    ##

    # Propagate the underling unwrapped pkg-config so that if you
    # install the wrapper, you get anything else it might provide.
    ''
      printWords ${pkg-config} > $out/nix-support/propagated-user-env-packages
    ''

    ##
    ## Man page and doc support
    ##
    + optionalString propagateDoc (
      ''
        ln -s ${pkg-config.man} $man
      ''
      + optionalString (pkg-config ? doc) ''
        ln -s ${pkg-config.doc} $doc
      ''
    )

    + ''
      install -m444 -T ${addFlags} $out/nix-support/add-flags.sh
      install -m444 -T ${utils} $out/nix-support/utils.bash
    ''

    ##
    ## Extra custom steps
    ##
    + extraBuildCommands;

  meta =
    let
      pkg-config_ = optionalAttrs (pkg-config != null) pkg-config;
    in
    (optionalAttrs (pkg-config_ ? meta) (
      removeAttrs pkg-config.meta [
        "priority"
        "mainProgram"
      ]
    ))
    // {
      description = attrByPath [ "meta" "description" ] "pkg-config" pkg-config_ + " (wrapper script)";
      priority = 10;
      mainProgram = wrapperBinName;
    };
}
