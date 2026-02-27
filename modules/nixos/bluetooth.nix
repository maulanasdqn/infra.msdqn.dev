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

  # Packages tambahan
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman
    usbutils  # untuk lsusb
  ];
}
