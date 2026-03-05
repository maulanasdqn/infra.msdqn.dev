{
  description = "nix-anywhere: unified Nix configuration for All (NixOS, macOS, Cloud VPS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
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

    personal-website = {
      url = "github:maulanasdqn/personal-website/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hpyd = {
      url = "github:maulanasdqn/high-performance-youtube-downloader/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rkm-backend = {
      url = "git+ssh://git@github.com/rajawalikaryamulya/rkm-backend.git?ref=develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rkm-frontend = {
      url = "git+ssh://git@github.com/rajawalikaryamulya/rkm-frontend.git?ref=develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rkm-admin-frontend = {
      url = "git+ssh://git@github.com/rajawalikaryamulya/rkm-admin-frontend.git?ref=develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-pilot = {
      url = "github:maulanasdqn/nix-pilot/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rag-app = {
      url = "github:maulanasdqn/rust-rag-example/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    roasting-startup = {
      url = "github:maulanasdqn/roasting-startup/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    verychic-frontend = {
      url = "git+ssh://git@github.com/mrscraper-com/verychic-frontend.git?ref=testing";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kilat-app = {
      url = "git+ssh://git@github.com/maulanasdqn/kilat-app.git?ref=develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-native Kubernetes tools
    nix-csi = {
      url = "github:lillecarl/nix-csi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    easykubenix = {
      url = "github:lillecarl/easykubenix";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

    # dinix - disabled until flake.nix is added to repo
    # dinix = {
    #   url = "github:lillecarl/dinix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      determinate,
      nixvim,
      sops-nix,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      disko,
      personal-website,
      hpyd,
      rkm-backend,
      rkm-frontend,
      rkm-admin-frontend,
      nix-pilot,
      rag-app,
      roasting-startup,
      verychic-frontend,
      kilat-app,
      clan-core,
      nix-csi,
      easykubenix,
      claude-code,
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

      darwinSpecialArgs = {
        username = config.darwinUsername;
        enableTilingWM = config.darwinEnableTilingWM;
        inherit
          nixvim
          enableLaravel
          enableRust
          enableVolta
          enableGolang
          sshKeys
          sops-nix
          secretsFile
          clan-core
          claude-code
          ;
      };

      workstationSpecialArgs = {
        username = config.workstationUsername;
        enableTilingWM = config.workstationEnableTilingWM;
        inherit
          nixvim
          enableLaravel
          enableRust
          enableVolta
          enableGolang
          sshKeys
          ;
      };

      hostingerSpecialArgs = {
        username = "root";
        hostname = config.vpsHostingerHostname;
        ipAddress = config.vpsHostingerIP;
        gateway = config.vpsHostingerGateway;
        enableLaravel = false;
        inherit nixvim sshKeys acmeEmail sops-nix secretsFile kilat-app;
        inherit nix-csi easykubenix;
        # Frontend flakes for stable symlinks
        inherit rkm-frontend rkm-admin-frontend verychic-frontend;
      };

      digitaloceanSpecialArgs = {
        username = config.vpsDigitalOceanUsername;
        hostname = config.vpsDigitalOceanHostname;
        enableLaravel = false;
        inherit nixvim sshKeys acmeEmail;
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
          services = { };
          machines.${config.darwinHostname}.machineClass = "darwin";
        };

        machines = {
          # Darwin (macOS)
          ${config.darwinHostname} = {
            nixpkgs.hostPlatform = "aarch64-darwin";
            imports = [
              determinate.darwinModules.default
              home-manager.darwinModules.home-manager
              nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  enable = true;
                  enableRosetta = true;
                  user = config.darwinUsername;
                  autoMigrate = true;
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
              (
                { ... }:
                {
                  _module.args = darwinSpecialArgs;
                  # Local machine - requires SSH enabled on Mac (System Settings > Sharing > Remote Login)
                  clan.core.networking.targetHost = "ms@localhost";
                }
              )
            ];
          };

          # NixOS Workstation
          ${config.workstationHostname} = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [
              ./hosts/workstation
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = workstationSpecialArgs;
                  backupFileExtension = "backup";
                };
              }
              ./modules/home/nixos.nix
              (
                { ... }:
                {
                  _module.args = workstationSpecialArgs;
                }
              )
            ];
          };

          # Hostinger VPS
          hostinger = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [
              # disko and sops-nix are provided by clan-core
              personal-website.nixosModules.default
              rkm-backend.nixosModules.default
              rkm-frontend.nixosModules.default
              rkm-admin-frontend.nixosModules.default
              roasting-startup.nixosModules.default
              verychic-frontend.nixosModules.default
              kilat-app.nixosModules.default
              # rag-app.nixosModules.default  # Temporarily disabled
              # nix-pilot.nixosModules.default  # Disabled - needs recursion_limit fix in np-ui
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

          # DigitalOcean VPS
          digitalocean = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [
              # disko is provided by clan-core
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
        };
      };
    in
    {
      # Inherit configurations from clan
      inherit (clan.config) nixosConfigurations darwinConfigurations clanInternals;
      clan = clan.config;

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
