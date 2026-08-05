{
  lib,
  stdenv,
  kernel,
}:

stdenv.mkDerivation {
  pname = "asup1303-hid";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KERNELRELEASE=${kernel.modDirVersion}"
  ];

  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];

  meta = {
    description = "Out-of-tree HID driver for the ASUP1303 (093a:3003) touchpad";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
