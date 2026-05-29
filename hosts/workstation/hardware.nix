{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.kernelParams = [
    "acpi.ec_no_wakeup=1"
    "resume_offset=112570368"
    "hibernate=shutdown"
    # NOTE: acpi_osi="Windows 2020" override removed — it changed Asus DSDT
    # device enumeration and hung early boot at "Starting Virtual Console".
    # It was only there for the ASUP1303 touchpad, which we no longer patch.
  ];

  boot.resumeDevice = "/dev/disk/by-uuid/839aa9c0-07fc-4019-abdf-2966b5794881";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disabled: triggers a full kernel rebuild on every nixos-rebuild switch.
  # Re-enable when the ASUP1303 touchpad quirk is actually needed.
  # boot.kernelPatches = [
  #   {
  #     name = "i2c-hid-asup1303-quirks";
  #     patch = ../../patches/i2c-hid-asup1303-quirks.patch;
  #   }
  # ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/839aa9c0-07fc-4019-abdf-2966b5794881";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3C0C-1B05";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/a1b612d4-776f-4f8c-be3b-7f4566760a22"; }
    {
      device = "/var/swapfile";
      size = 42 * 1024;
    }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
