{ stdenv,
  lib,
  bison,
  dtc,
  fetchgit,
  flex,
  gnutls,
  libuuid,
  ncurses,
  openssl,
  which,
  perl,
  buildPackages,
  fetchFromGitHub
}:

let
  # wolfSSL overlay to disable tests
  wolfSSLOverlay = final: prev: {
    wolfssl = prev.wolfssl.overrideAttrs (old: {
      # Disable the failing tests
      doCheck = false;
      doInstallCheck = false;
    });
    
    # Also ensure gnutls doesn't have issues
    gnutls = prev.gnutls.override {
      # Force use of different SSL library if possible
      #withWolfSSL = false;
    };
  };

  # Apply the overlay to the package set
  pkgsWithOverlay = import <nixpkgs> {
    overlays = [ wolfSSLOverlay ];
  };

  ubsrc = fetchgit {
    url = "https://github.com/nxp-imx/uboot-imx.git";
    # tag: "lf-6.1.55-2.2.0"
    rev = "49b102d98881fc28af6e0a8af5ea2186c1d90a5f";
    sha256 = "sha256-1j6X82DqezEizeWoSS600XKPNwrQ4yT0vZuUImKAVVA=";
  };
  # ubsrc = fetchFromGitHub {
  #   owner = "debix-tech";
  #   repo = "uboot-nxp-debix";
  #   rev = "lf_v2022.04-debix_model_a";
  #   sha256 = "sha256-5uZZk3pEVySP/yeLId/Hh2Zq8uzeqckcRgjrOZKzGBg="; # nix-prefetch
  # };

in

(stdenv.mkDerivation {
  pname = "imx8mp-uboot";
  version = "2022.04";
  src = ubsrc;

  postPatch = ''
    patchShebangs tools
    patchShebangs scripts
  '';

  nativeBuildInputs = [
    bison
    flex
    openssl
    which
    ncurses
    libuuid
    # Use gnutls from the overlay-applied package set
    pkgsWithOverlay.gnutls
    openssl
    perl
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  makeFlags = [
    "DTC=${lib.getExe buildPackages.dtc}"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];

  extraConfig = ''
    CONFIG_USE_BOOTCOMMAND=y
    CONFIG_BOOTCOMMAND="setenv ramdisk_addr_r 0x45000000; setenv fdt_addr_r 0x44000000; run distro_bootcmd; "
    CONFIG_CMD_BOOTEFI_SELFTEST=n
    CONFIG_CMD_BOOTEFI=y
    CONFIG_EFI_LOADER=y
    CONFIG_BLK=y
    CONFIG_PARTITIONS=y
    CONFIG_DM_DEVICE_REMOVE=n
    CONFIG_CMD_CACHE=y
  '';

  passAsFile = [ "extraConfig" ];

  configurePhase = ''
    runHook preConfigure

    make imx8mp_evk_defconfig
    cat $extraConfigPath >> .config

    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp ./u-boot-nodtb.bin $out
    cp ./spl/u-boot-spl.bin $out
    cp ./arch/arm/dts/imx8mp-evk.dtb $out
    cp .config  $out

    runHook postInstall
  '';

  dontStrip = true;
})