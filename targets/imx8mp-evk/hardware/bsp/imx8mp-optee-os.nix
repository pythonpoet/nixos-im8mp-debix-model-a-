{ pkgs }:
let
  python3 = pkgs.buildPackages.python3;
  toolchain = pkgs.gcc9Stdenv.cc;
  binutils = pkgs.gcc9Stdenv.cc.bintools.bintools_bin;
  # Use the CROSS-COMPILER's cpp, not the host's!
  cpp = "${toolchain}/bin/${toolchain.targetPrefix}cpp";
in
pkgs.stdenv.mkDerivation rec {
  pname = "imx8mp-optee-os";
  version = "lf-6.1.55-2.2.0";

  nativeBuildInputs = [
    python3
    # Add the cross-compilation toolchain to PATH
    toolchain
    binutils
  ];

  enableParallelBuilding = true;

  propagatedBuildInputs = with python3.pkgs; [
    pycryptodomex
    pyelftools
    cryptography
  ];

  src = pkgs.fetchgit {
    url = "https://github.com/nxp-imx/imx-optee-os.git";
    rev = "a303fc80f7c4bd713315687a1fa1d6ed136e78ee";
    sha256 = "sha256-OpyG812DX0c06bRZPKWB2cNu6gtZCOvewDhsKgrGB+s=";
  };

  postPatch = ''
    substituteInPlace scripts/arm32_sysreg.py \
      --replace '/usr/bin/env python3' '${python3}/bin/python'
    substituteInPlace scripts/gen_tee_bin.py \
      --replace '/usr/bin/env python3' '${python3}/bin/python'
    substituteInPlace scripts/pem_to_pub_c.py \
      --replace '/usr/bin/env python3' '${python3}/bin/python'
    substituteInPlace ta/pkcs11/scripts/verify-helpers.sh \
      --replace '/bin/bash' '${pkgs.bash}/bin/bash'
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))objcopy" ${binutils}/bin/${toolchain.targetPrefix}objcopy
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))objdump" ${binutils}/bin/${toolchain.targetPrefix}objdump
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))nm" ${binutils}/bin/${toolchain.targetPrefix}nm
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))readelf" ${binutils}/bin/${toolchain.targetPrefix}readelf
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))ar" ${binutils}/bin/${toolchain.targetPrefix}ar
    # FIXED: Use the cross-compiler's cpp, not the host's
    substituteInPlace mk/gcc.mk \
      --replace "\$(CROSS_COMPILE_\$(sm))cpp" "${cpp}"
  '';

  # Set environment variables for the cross-compilation tools
  preBuild = ''
    export CC="${toolchain}/bin/${toolchain.targetPrefix}gcc"
    export CXX="${toolchain}/bin/${toolchain.targetPrefix}g++"
    export CPP="${cpp}"
    export AR="${toolchain}/bin/${toolchain.targetPrefix}ar"
    export OBJCOPY="${toolchain}/bin/${toolchain.targetPrefix}objcopy"
    export OBJDUMP="${toolchain}/bin/${toolchain.targetPrefix}objdump"
    export READELF="${toolchain}/bin/${toolchain.targetPrefix}readelf"
    export NM="${toolchain}/bin/${toolchain.targetPrefix}nm"
  '';

  makeFlags = [
    "PLATFORM=imx"
    "PLATFORM_FLAVOR=mx8mpevk"
    "CFG_ARM64_core=y"
    "CFG_TEE_TA_LOG_LEVEL=0"
    "CFG_TEE_CORE_LOG_LEVEL=0"
    "CROSS_COMPILE=${toolchain}/bin/${toolchain.targetPrefix}"
    "CROSS_COMPILE64=${toolchain}/bin/${toolchain.targetPrefix}"
  ];

  installPhase = ''
    mkdir -p $out
    cp ./out/arm-plat-imx/core/tee-raw.bin $out/tee.bin
  '';
}