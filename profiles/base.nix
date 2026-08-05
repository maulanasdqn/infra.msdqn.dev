{
  lib,
  pkgs,
  username,
  sshKeys,
  ...
}:
{

  assertions = [
    {
      assertion = sshKeys != [];
      message = "sshKeys must not be empty - you will be locked out!";
    }
  ];

  time.timeZone = lib.mkDefault "Asia/Jakarta";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    tmp.cleanOnBoot = true;
  };

  users.mutableUsers = true;

  users.users = lib.mkMerge [
    (lib.mkIf (username != "root") {
      ${username} = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = sshKeys;
        createHome = true;
        home = "/home/${username}";
      };
    })
    {
      root.openssh.authorizedKeys.keys = sshKeys;
    }
  ];

  programs.zsh.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev:
      let
        jediFix = pyfinal: pyprev: {
          jedi-language-server = pyprev.jedi-language-server.overridePythonAttrs (old: {
            dontCheckRuntimeDeps = true;
          });
        };
      in {
        python3Packages = prev.python3Packages.overrideScope jediFix;
        python313Packages = prev.python313Packages.overrideScope jediFix;
        python3 = prev.python3.override { packageOverrides = jediFix; };
        python313 = prev.python313.override { packageOverrides = jediFix; };
      })
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  system.stateVersion = "25.05";
}
