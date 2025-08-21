# NixOS on NXP iMX8 MQuad platform

This flake enables cross-compilation of sdimage for NXP iMX8 MQuad evaluation kit from an x86 machine.

To generate an SD image run the following command:

```
 $> nix build .#packages.x86_64-linux.imx8mp-evk-release
```

After successful compilation it generates sdimage `./result/nixos.img` which can be programmed in sdcard to boot the board.

To program the sdimage use following command: 

```
 $> sudo dd if=.result/nixos.img of=/dev/sd<x> bs=32M
```

Once image is programmed in the sdcard, put the sdcard in the card slot of the board and reboot. 
