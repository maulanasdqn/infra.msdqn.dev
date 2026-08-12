{
  description = "nix-anywhere: unified Nix configuration for All (NixOS, macOS, Cloud VPS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

    nix-on-droid = {
      url = "github:maulanasdqn/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager-stable";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      home-manager,
      mac-app-util,
      determinate,
      nixvim,
      nixvim-stable,
      sops-nix,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      disko,
      clan-core,
      claude-code,
      nix-on-droid,
      nixos-wsl,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      defaultConfig = import ./config.nix;
      localConfigPath = ./config.local.nix;
      config =
        if builtins.pathExists localConfigPath then
          defaultConfig // (import localConfigPath)
        else
          defaultConfig;

      inherit (config)
        sshKeys
        acmeEmail
        enableLaravel
        enableRust
        enableVolta
        enableGolang
        ;
      secretsFile = ./secrets/secrets.yaml;

      darwinBaseSpecialArgs = {
        username = config.darwinUsername;
        enableTilingWM = config.darwinEnableTilingWM;
        inherit
          nixvim
          nixpkgs-stable
          enableLaravel
          enableRust
          enableVolta
          enableGolang
          sshKeys
          sops-nix
          secretsFile
          clan-core
          claude-code
          mac-app-util
          ;
      };

      mkDarwinSpecialArgs =
        aggressive:
        darwinBaseSpecialArgs
        // {
          enableAggressiveTweaks = aggressive;
        };

      mkDarwinMachine =
        { hostModule, aggressive }:
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          imports = [
            determinate.darwinModules.default
            home-manager.darwinModules.home-manager
            mac-app-util.darwinModules.default
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = config.darwinUsername;
                autoMigrate = false;
                mutableTaps = false;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };
              };
            }
            ./modules/nix.nix
            ./modules/darwin
            ./modules/home/darwin.nix
            hostModule
            (
              { ... }:
              {
                _module.args = mkDarwinSpecialArgs aggressive;

                home-manager.extraSpecialArgs = mkDarwinSpecialArgs aggressive;

                clan.core.networking.targetHost = "ms@localhost";
              }
            )
          ];
        };

      mkWorkstationSpecialArgs =
        { username, enableTilingWM }:
        {
          inherit username enableTilingWM;
          inherit
            nixvim
            enableLaravel
            enableRust
            enableVolta
            enableGolang
            sshKeys
            claude-code
            ;
        };

      mkWorkstationMachine =
        {
          hostModule,
          username,
          enableTilingWM,
        }:
        let
          specialArgs = mkWorkstationSpecialArgs { inherit username enableTilingWM; };
        in
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          imports = [
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs;
                backupFileExtension = "backup";
              };
            }
            ./modules/home/nixos.nix
            (
              { ... }:
              {
                _module.args = specialArgs;
              }
            )
          ];
        };

      wslSpecialArgs = {
        username = config.wslUsername;
        enableTilingWM = false;
        inherit
          nixvim
          enableLaravel
          enableRust
          enableVolta
          enableGolang
          sshKeys
          claude-code
          ;
      };

      hostingerSpecialArgs = {
        username = "root";
        hostname = config.vpsHostingerHostname;
        ipAddress = config.vpsHostingerIP;
        gateway = config.vpsHostingerGateway;
        enableLaravel = false;
        inherit
          nixvim
          sshKeys
          acmeEmail
          sops-nix
          secretsFile
          ;
      };

      digitaloceanSpecialArgs = {
        username = config.vpsDigitalOceanUsername;
        hostname = config.vpsDigitalOceanHostname;
        enableLaravel = false;
        inherit nixvim sshKeys acmeEmail;
      };

      raspiSpecialArgs = {
        username = "ms";
        enableLaravel = false;
        inherit
          nixvim
          sshKeys
          claude-code
          ;
      };

      isDarwin =
        system:
        builtins.elem system [
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      clan = clan-core.lib.clan {
        inherit self;
        meta.name = "msdqn";
        meta.domain = "msdqn.dev";

        inventory = {
          machines.macmini-mrscraper.machineClass = "darwin";
          machines.macbook-mrscraper.machineClass = "darwin";
          machines.beast.machineClass = "darwin";
        };

        machines = {

          macmini-mrscraper = mkDarwinMachine {
            hostModule = ./hosts/darwin/macmini-mrscraper;
            aggressive = false;
          };

          macbook-mrscraper = mkDarwinMachine {
            hostModule = ./hosts/darwin/macbook-mrscraper;
            aggressive = true;
          };

          beast = mkDarwinMachine {
            hostModule = ./hosts/darwin/beast;
            aggressive = true;
          };

          ${config.workstationVivobookHostname} = mkWorkstationMachine {
            hostModule = ./hosts/workstation/vivobook;
            username = config.workstationVivobookUsername;
            enableTilingWM = config.workstationVivobookEnableTilingWM;
          };

          ${config.workstationPcHostname} = mkWorkstationMachine {
            hostModule = ./hosts/workstation/pc;
            username = config.workstationPcUsername;
            enableTilingWM = config.workstationPcEnableTilingWM;
          };

          hostinger = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [

              ./hosts/vps/hostinger
              (
                { ... }:
                {
                  _module.args = hostingerSpecialArgs;
                  clan.core.networking.targetHost = config.vpsHostingerIP;
                }
              )
            ];
          };

          digitalocean = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [

              ./hosts/vps/digitalocean
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = digitaloceanSpecialArgs;
                  backupFileExtension = "backup";
                };
              }
              ./modules/home/nixos-server.nix
              (
                { ... }:
                {
                  _module.args = digitaloceanSpecialArgs;
                }
              )
            ];
          };

          raspi = {
            nixpkgs.hostPlatform = "aarch64-linux";
            imports = [

              ./hosts/raspi
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = raspiSpecialArgs;
                  backupFileExtension = "backup";
                };
              }
              ./modules/home/nixos-raspi.nix
              (
                { ... }:
                {
                  _module.args = raspiSpecialArgs;
                  clan.core.networking.targetHost = "ms@raspi.local";
                }
              )
            ];
          };
        };
      };
    in
    {

      inherit (clan.config) darwinConfigurations clanInternals;
      clan = clan.config;

      nixosConfigurations = clan.config.nixosConfigurations // {
        wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = wslSpecialArgs;
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = wslSpecialArgs;
                backupFileExtension = "backup";
              };
            }
            ./modules/home/wsl.nix
          ];
        };
      };

      nixOnDroidConfigurations =
        let
          mkNixOnDroid =
            {
              hostModule,
              pkgsSrc ? nixpkgs,
              extraSpecialArgs ? { },
            }:
            nix-on-droid.lib.nixOnDroidConfiguration {
              pkgs = import pkgsSrc {
                system = "aarch64-linux";
                overlays = [ nix-on-droid.overlays.default ];
                config.allowUnfree = true;
              };
              inherit extraSpecialArgs;
              modules = [ hostModule ];
            };
        in
        {
          default = mkNixOnDroid { hostModule = ./hosts/android; };
          android = mkNixOnDroid { hostModule = ./hosts/android; };

          honor = mkNixOnDroid {
            hostModule = ./hosts/android/honor;
            pkgsSrc = nixpkgs-stable;
            extraSpecialArgs = {
              inherit claude-code;

              nixvim = nixvim-stable;
              nixpkgs = nixpkgs-stable;
            };
          };
        };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              (writeShellApplication {
                name = "rebuild";
                runtimeInputs = if isDarwin system then [ nix-darwin.packages.${system}.darwin-rebuild ] else [ ];
                text =
                  if isDarwin system then
                    ''
                      echo "Rebuilding nix-darwin configuration..."
                      sudo darwin-rebuild switch --flake .
                      echo "Done!"
                    ''
                  else
                    ''
                      echo "Rebuilding NixOS configuration..."
                      sudo nixos-rebuild switch --flake .
                      echo "Done!"
                    '';
              })
              nixfmt
              clan-core.packages.${system}.clan-cli
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
