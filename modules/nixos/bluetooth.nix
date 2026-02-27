{ pkgs, ... }:
{
  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
        Privacy = "device";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Blueman GUI untuk manage Bluetooth
  services.blueman.enable = true;

  # RFCOMM bind untuk SMARTCOM BT-801 thermal printer (RPP02N)
  # MAC Address: 86:67:7A:CE:07:41, Channel: 1
  systemd.services.rfcomm-printer = {
    description = "Bind RFCOMM0 to SMARTCOM BT-801 Bluetooth Thermal Printer";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bluez}/bin/rfcomm bind 0 86:67:7A:CE:07:41 1";
      ExecStop = "${pkgs.bluez}/bin/rfcomm release 0";
    };
  };

  # Udev rule untuk set permission /dev/rfcomm0 agar bisa diakses CUPS
  services.udev.extraRules = ''
    KERNEL=="rfcomm[0-9]*", MODE="0666", GROUP="lp"
  '';

  # Packages tambahan
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman
    usbutils  # untuk lsusb
  ];
}
