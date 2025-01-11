{
  lib,
  stdenv,
  callPackage,
  makeSetupHook,
  hostPlatform_ ? null,
  buildPackages
}:

# See the header comment in ./setup-hook.sh for example usage.
makeSetupHook {
  name = "install-shell-files";
  substitutions = {
    canExecute = if hostPlatform_ != null then lib.debug.traceValFn (v: "canExecute ${builtins.toString v}") (if stdenv.buildPlatform.canExecute hostPlatform_ then 1 else 0) else 0;
    emulatorAvailable = if hostPlatform_ != null then lib.debug.traceValFn (v: "emulatorAvailable ${builtins.toString v}") (if hostPlatform_.emulatorAvailable buildPackages then 1 else 0) else 0;
    emulator = if hostPlatform_ != null then lib.debug.traceVal (hostPlatform_.emulator buildPackages) else 0;
    buildPlatform = lib.debug.traceValFn (v: "buildPlatform ${v}") stdenv.buildPlatform.config;
    hostPlatform = if hostPlatform_ != null then lib.debug.traceValFn (v: "hostPlatform ${v}") hostPlatform_.config else "";
  };
  passthru = {
    tests = lib.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = ./tests;
    };
  };
} ./setup-hook.sh
