{
  cmake,
  cudatoolkit,
  fetchFromGitHub,
  gfortran,
  lib,
  llvmPackages,
  python3Packages,
  cudaPackages,
  stdenv,
  config,
  testers,
  bitStreamWordSize ? 64,
  enableCfp ? true,
  enableCuda ? config.cudaSupport,
  enableFortran ? builtins.elem stdenv.hostPlatform.system gfortran.meta.platforms,
  enableOpenMP ? true,
  enablePython ? true,
  enableUtilities ? true,
}@inputs:

let
  stdenv = throw "Use effectiveStdenv instead";
  effectiveStdenv = if enableCuda then cudaPackages.backendStdenv else inputs.stdenv;
in

effectiveStdenv.mkDerivation (finalAttrs: {
  pname = "zfp";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "LLNL";
    repo = "zfp";
    tag = finalAttrs.version;
    hash = "sha256-iZxA4lIviZQgaeHj6tEQzEFSKocfgpUyf4WvUykb9qk=";
  };

  patches = [
    # part of https://github.com/LLNL/zfp/pull/217
    # Remove distutils
    ./python312.patch
  ];

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals enableFortran [
    gfortran
  ]
  ++ lib.optionals enablePython (
    with python3Packages;
    [
      cython
      numpy
      python
    ]
  );

  buildInputs = lib.optionals enableCuda [
    cudatoolkit
  ];

  propagatedBuildInputs = lib.optionals (enableOpenMP && effectiveStdenv.cc.isClang) [
    llvmPackages.openmp
  ];

  strictDeps = true;

  # compile CUDA code for all extant GPUs so the binary will work with any GPU
  # and driver combination. to be ultimately solved upstream:
  # https://github.com/LLNL/zfp/issues/178
  # NB: not in cmakeFlags due to https://github.com/NixOS/nixpkgs/issues/114044
  preConfigure = lib.optionalString enableCuda ''
    cmakeFlags+=(
      "-DCMAKE_CUDA_FLAGS=-gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_60,code=sm_60 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_86,code=sm_86 -gencode=arch=compute_87,code=sm_87 -gencode=arch=compute_86,code=compute_86"
    )
  '';

  cmakeFlags = [
    (lib.cmakeBool "BUILD_UTILITIES" enableUtilities)
    (lib.cmakeBool "BUILD_CFP" enableCfp)
    (lib.cmakeBool "ZFP_WITH_CUDA" enableCuda)
    (lib.cmakeBool "BUILD_ZFORP" enableFortran)
    (lib.cmakeBool "ZFP_WITH_OPENMP" enableOpenMP)
    (lib.cmakeBool "BUILD_ZFPY" enablePython)
  ]
  ++ lib.optionals (bitStreamWordSize != 64) [
    (lib.cmakeFeature "ZFP_BIT_STREAM_WORD_SIZE" (toString bitStreamWordSize))
  ];

  doCheck = true;

  # the testzfp regression test only supports the default 64-bit bitstream word
  preCheck = lib.optionalString (bitStreamWordSize != 64) ''
    checkFlags+=(ARGS="--exclude-regex testzfp")
  '';

  passthru.tests = {
    cmake-config = testers.hasCmakeConfigModules {
      moduleNames = [ "zfp" ];
      package = finalAttrs.finalPackage;
    };
  };

  __structuredAttrs = true;

  meta = {
    homepage = "https://computing.llnl.gov/projects/zfp";
    description = "Library for random-access compression of floating-point arrays";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.spease ];
    # 64-bit only
    platforms = lib.platforms.aarch64 ++ lib.platforms.x86_64;
    mainProgram = "zfp";
  };
})
