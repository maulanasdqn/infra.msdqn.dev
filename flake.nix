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

    # Stable home-manager for nix-on-droid (honor): hm master requires
    # nixpkgs-unstable internals (lib/services), which nixpkgs 25.11 lacks.
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

    # Stable nixvim for nix-on-droid (honor): nixvim main pins neovim 0.12
    # from nixpkgs-unstable (glibc 2.42), which freezes at TUI startup under
    # proot (nix-on-droid #495/#539).
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

    bsm-landing = {
      url = "git+ssh://git@github.com/bsmart-cerdas-indonesia/bsm-landing.git?ref=develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kolaborium = {
      url = "git+ssh://git@github.com/bsmart-cerdas-indonesia/kolaborium.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs-stable";
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
      hpyd,
      rkm-backend,
      rkm-frontend,
      rkm-admin-frontend,
      nix-pilot,
      rag-app,
      roasting-startup,
      bsm-landing,
      kolaborium,
      clan-core,
      claude-code,
      claude-desktop,
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

      # enableAggressiveTweaks gates machine-wide / single-owner behavior:
      #   firmware NVRAM boot-args, HID keyboard remap, global power management,
      #   performance LaunchDaemons, system-wide PostgreSQL, and brew cleanup=zap.
      # true  -> MacBook (sole owner)        false -> shared Mac mini (safe defaults)
      mkDarwinSpecialArgs = aggressive: darwinBaseSpecialArgs // {
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
            hostModule
            (
              { ... }:
              {
                _module.args = mkDarwinSpecialArgs aggressive;
                # Pass the same specialArgs into home-manager so nixvim (and the
                # other shared inputs) are available to HM submodules at
                # import-resolution time. Without this, neovim/hm.nix references
                # `nixvim` in its `imports` list but can only see it via
                # `_module.args`, which triggers an infinite recursion.
                home-manager.extraSpecialArgs = mkDarwinSpecialArgs aggressive;
                # Local machine - requires SSH enabled on Mac (System Settings > Sharing > Remote Login)
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
            claude-desktop
            ;
        };

      mkWorkstationMachine =
        { hostModule, username, enableTilingWM }:
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
        inherit nixvim sshKeys acmeEmail sops-nix secretsFile;
        inherit rkm-frontend rkm-admin-frontend;
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
          machines.macmini-mrscraper.machineClass = "darwin";
          machines.macbook-mrscraper.machineClass = "darwin";
          machines.beast.machineClass = "darwin";
        };

        machines = {
          # Darwin (macOS) — shared Mac mini: trimmed, safe for the second account
          macmini-mrscraper = mkDarwinMachine {
            hostModule = ./hosts/darwin/macmini-mrscraper;
            aggressive = false;
          };

          # Darwin (macOS) — personal MacBook: full single-owner config
          macbook-mrscraper = mkDarwinMachine {
            hostModule = ./hosts/darwin/macbook-mrscraper;
            aggressive = true;
          };

          # Darwin (macOS) — beast: full single-owner config
          beast = mkDarwinMachine {
            hostModule = ./hosts/darwin/beast;
            aggressive = true;
          };

          # NixOS Workstation — Asus Vivobook laptop
          ${config.workstationVivobookHostname} = mkWorkstationMachine {
            hostModule = ./hosts/workstation/vivobook;
            username = config.workstationVivobookUsername;
            enableTilingWM = config.workstationVivobookEnableTilingWM;
          };

          # NixOS Workstation — desktop PC
          ${config.workstationPcHostname} = mkWorkstationMachine {
            hostModule = ./hosts/workstation/pc;
            username = config.workstationPcUsername;
            enableTilingWM = config.workstationPcEnableTilingWM;
          };

          # Hostinger VPS
          hostinger = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = [
              # disko and sops-nix are provided by clan-core
              rkm-backend.nixosModules.default
              rkm-frontend.nixosModules.default
              rkm-admin-frontend.nixosModules.default
              # roasting-startup.nixosModules.default
              bsm-landing.nixosModules.default
              kolaborium.nixosModules.default
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
                config.allowUnfree = true; # unrar and friends
              };
              inherit extraSpecialArgs;
              modules = [ hostModule ];
            };
        in
        {
          default = mkNixOnDroid { hostModule = ./hosts/android; };
          android = mkNixOnDroid { hostModule = ./hosts/android; };
          # Use the 25.11 release nixpkgs: it predates the glibc 2.42 / nix 2.31.3
          # change that broke nix-on-droid proot builds (#495), AND its aarch64
          # binaries (vim plugins, treesitter grammars, LSPs) are fully cached by
          # Hydra — so honor substitutes them instead of compiling on-device.
          honor = mkNixOnDroid {
            hostModule = ./hosts/android/honor;
            pkgsSrc = nixpkgs-stable;
            extraSpecialArgs = {
              inherit claude-code;
              # Stable nixvim: nixvim main brings neovim 0.12/glibc 2.42,
              # which freezes under proot — see nixvim-stable input comment.
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
