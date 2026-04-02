{
  darwinUsername = "your-username";
  darwinHostname = "your-mac-hostname";
  darwinEnableTilingWM = true;

  workstationUsername = "your-username";
  workstationPassword = "your-password";
  workstationHostname = "nixos";
  workstationEnableTilingWM = true;

  vpsHostingerUsername = "your-username";
  vpsHostingerHostname = "your-vps-hostname";
  vpsHostingerIP = "0.0.0.0";
  vpsHostingerGateway = "0.0.0.0";

  acmeEmail = "your-email@example.com";

  vpsDigitalOceanUsername = "your-username";
  vpsDigitalOceanHostname = "your-droplet-hostname";

  enableLaravel = true;
  enableRust = true;
  enableVolta = true;

  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-key@example.com"
  ];
}
