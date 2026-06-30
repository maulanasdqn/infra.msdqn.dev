# nix-anywhere

My personal unified Nix configuration for both **NixOS** and **macOS** (nix-darwin), with home-manager and nixvim.

## Structure

```
.
├── flake.nix                       # Main entry point
├── flake.lock
├── config.nix                      # User configuration (gitignored, local only)
├── config.example.nix              # Example configuration (copy to config.nix)
├── .envrc                          # Direnv integration
├── hosts/
│   ├── workstation/                # NixOS workstation configs
│   │   ├── vivobook/               # Asus Vivobook laptop
│   │   └── pc/                     # Desktop PC
│   └── vps/                        # VPS configurations (nixos-anywhere)
│       ├── hostinger/              # Hostinger VPS (static IP, BIOS)
│       │   ├── default.nix
│       │   ├── hardware.nix
│       │   ├── disk-config.nix
│       │   └── services/           # Self-hosted services
│       │       ├── n8n.nix
│       │       ├── uptime-kuma.nix
│       │       ├── netdata.nix
│       │       ├── glitchtip.nix
│       │       ├── mailserver.nix
│       │       ├── roundcube.nix
│       │       └── minio.nix
│       └── digitalocean/           # DigitalOcean Droplet (DHCP, hybrid boot)
├── profiles/
│   ├── base.nix                    # Base profile for all systems
│   └── server.nix                  # Server profile (hardened SSH, nginx, docker)
├── templates/                      # Devenv project templates
│   ├── laravel/
│   ├── nodejs/
│   └── rust/
└── modules/
    ├── nix.nix                     # Nix/Determinate settings
    ├── darwin/                     # macOS-specific modules
    │   ├── default.nix
    │   ├── defaults/               # macOS system defaults
    │   ├── fonts/
    │   ├── homebrew/
    │   ├── packages/
    │   ├── security/
    │   ├── system/
    │   ├── aerospace/              # Tiling WM + hotkeys
    │   └── sketchybar/             # Custom menu bar
    ├── nixos/                      # NixOS-specific modules
    │   ├── default.nix
    │   ├── boot.nix
    │   ├── hardware.nix
    │   ├── networking.nix
    │   ├── locale.nix
    │   ├── desktop.nix
    │   ├── audio.nix
    │   ├── users.nix
    │   ├── fonts.nix
    │   ├── programs.nix
    │   ├── nix.nix
    │   └── git-sync.nix            # VPS config sync from git
    └── home/
        ├── darwin.nix              # macOS home entry point
        ├── nixos.nix               # NixOS home entry point
        ├── packages/
        │   ├── darwin.nix          # macOS packages
        │   └── nixos.nix           # NixOS packages
        ├── hyprland/               # NixOS-only (Wayland compositor)
        ├── vscode/                 # NixOS-only
        ├── docker/                 # macOS-only (Colima)
        ├── ghostty/                # macOS-only
        ├── laravel/                # macOS-only
        ├── services/               # macOS-only
        ├── sketchybar/             # macOS-only
        ├── sops/                   # macOS-only
        ├── wallpaper/              # macOS-only
        └── ... (shared)
            ├── git/
            ├── neovim/
            ├── starship/
            ├── ssh/
            ├── tmux/
            └── zsh/
```

## What's Included

### Shared (Both Platforms)

| Component | Description |
|-----------|-------------|
| **Neovim** | Full IDE with LSP, Treesitter, Telescope, Rose Pine theme |
| **Zsh** | Oh-My-Zsh, syntax highlighting, autosuggestions |
| **Starship** | Cross-shell prompt |
| **Tmux** | Terminal multiplexer with Rose Pine theme |
| **Git** | Git configuration with delta |

### macOS (nix-darwin)

| Component | Description |
|-----------|-------------|
| **AeroSpace** | Tiling window manager + hotkeys (optional) |
| **Sketchybar** | Custom menu bar (optional) |
| **Ghostty** | GPU-accelerated terminal |
| **Homebrew** | Casks and formulae |
| **Colima** | Docker runtime |
| **Laravel** | PHP development environment (optional) |
| **Sops-nix** | Secrets management |

### NixOS

| Component | Description |
|-----------|-------------|
| **GNOME** | Desktop environment (default) |
| **Hyprland** | Wayland compositor (optional) |
| **Waybar** | Status bar (optional) |
| **Wofi** | Application launcher (optional) |
| **VSCode** | Visual Studio Code |
| **PipeWire** | Audio |

## Installation

### macOS

```bash
# Prerequisites: Determinate Nix
# https://determinate.systems/posts/determinate-nix-installer

# Clone the repo
git clone git@github.com:maulanasdqn/nix-anywhere.git ~/.config/nix
cd ~/.config/nix

# Create your configuration
cp config.example.nix config.nix
nvim config.nix

# Build and apply
nix develop --command rebuild
```

### Workstation (NixOS)

```bash
# Clone the repo
git clone git@github.com:maulanasdqn/nix-anywhere.git ~/.config/nix
cd ~/.config/nix

# Create your configuration
cp config.example.nix config.nix
nvim config.nix

# Generate hardware config (first time only)
sudo nixos-generate-config --show-hardware-config > hosts/workstation/vivobook/hardware.nix

# Build and apply (pick the machine: vivobook or pc)
sudo nixos-rebuild switch --flake .#vivobook
sudo nixos-rebuild switch --flake .#pc
```

### VPS Deployment (nixos-anywhere)

Deploy NixOS to a fresh VPS running Ubuntu/Debian:

```bash
# Hostinger VPS (uses static IP, BIOS boot, LTS kernel)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hostinger --build-on remote root@<VPS_IP>

# DigitalOcean Droplet (uses DHCP, hybrid BIOS/EFI boot)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#digitalocean --build-on remote root@<VPS_IP>
```

#### Using Cachix for Faster Deployments

Pre-built binaries are available on Cachix. For faster fresh VPS deployments:

```bash
# Deploy with Cachix substituter (skips building Rust/Node apps from scratch)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hostinger --build-on remote \
  --env 'NIX_CONFIG=extra-substituters = https://msdqn.cachix.org; extra-trusted-public-keys = msdqn.cachix.org-1:ZXbpVr3DqsceNIVLZEfXdXlnPOPxak/PKztmFXBqnfI=' \
  root@<VPS_IP>
```

#### Build Here, Deploy There

Since local Mac (aarch64-darwin) can't cross-compile to VPS (x86_64-linux), use an existing VPS as remote builder:

```bash
# Build on VPS and deploy to another VPS
ssh root@<BUILD_VPS_IP> "nixos-rebuild switch --flake /etc/nixos#<TARGET_CONFIG> --target-host root@<TARGET_VPS_IP>"
```

**VPS Provider Configurations:**

| Provider | Boot Mode | Disk Device | Network | Kernel |
|----------|-----------|-------------|---------|--------|
| Hostinger | BIOS (GRUB) | `/dev/sda` | Static IP | LTS 6.6 |
| DigitalOcean | Hybrid BIOS/EFI | `/dev/vda` | DHCP | Latest |

**Note:** Configure your VPS settings in `config.nix` before deployment. The file is gitignored - copy from `config.example.nix`.

### Pre-built Packages on Cachix

The following heavy packages are pre-built and available on `msdqn.cachix.org`:

| Package | Description | Size |
|---------|-------------|------|
| **ydm-api** | YDM API Gateway (Rust) | ~45 MiB |
| **ydm-auth-server** | YDM Auth gRPC Service (Rust) | ~50 MiB |
| **ydm-companions-server** | YDM Companions gRPC (Rust) | ~13 MiB |
| **ydm-conversations-server** | YDM Conversations gRPC (Rust) | ~15 MiB |
| **ydm-subscriptions-server** | YDM Subscriptions gRPC (Rust) | ~14 MiB |
| **ydm-storage-server** | YDM Storage gRPC (Rust) | ~18 MiB |
| **ydm-voice-server** | YDM Voice gRPC (Rust) | ~7 MiB |
| **ydm-frontend** | YDM Frontend (Next.js) | ~164 MiB |
| **echo-backend** | Echo Backend API (Rust) | ~64 MiB |
| **bundle-social-service** | Bundle Social (NestJS) | ~100 MiB |
| **bsmart-landing** | BSmart Landing (Next.js) | ~37 MiB |

### VPS Services (Hostinger)

The Hostinger VPS includes the following self-hosted services:

| Service | Description | URL Pattern |
|---------|-------------|-------------|
| **Personal Website** | Astro SSR application | `yourdomain.com` |
| **n8n** | Workflow automation | `n8n.yourdomain.com` |
| **Uptime Kuma** | Uptime monitoring | `uptime.yourdomain.com` |
| **Netdata** | System monitoring | `netdata.yourdomain.com` |
| **Glitchtip** | Error tracking (Sentry alternative) | `glitchtip.yourdomain.com` |
| **Mail Server** | Full email server (docker-mailserver) | `mail.yourdomain.com` |
| **Roundcube** | Webmail client | `webmail.yourdomain.com` |
| **Minio** | S3-compatible object storage | `minio.yourdomain.com` / `s3.yourdomain.com` |

#### Required Environment Files

Each service requires environment files with secrets. Create these on the VPS before deployment:

```bash
# Glitchtip
/etc/glitchtip.env          # DATABASE_URL, SECRET_KEY, REDIS_URL, etc.
/etc/glitchtip-postgres.env # POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Mail Server
/etc/mailserver.env         # SSL_TYPE, SSL_CERT_PATH, SSL_KEY_PATH, etc.

# Roundcube
/etc/roundcube.env          # ROUNDCUBEMAIL_DB_*, etc.
/etc/roundcube-db.env       # POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Minio
/etc/minio.env              # MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, etc.

# Personal Website
/etc/personal-website.env   # SENTRY_DSN, etc.
```

#### Required DNS Records

For the mail server to work properly, add these DNS records:

| Type | Name | Value |
|------|------|-------|
| A | `mail` | `<VPS_IP>` (DNS only, no proxy) |
| A | `minio` | `<VPS_IP>` |
| A | `s3` | `<VPS_IP>` |
| MX | `@` | `mail.yourdomain.com` (priority 10) |
| TXT | `@` | `v=spf1 mx a:mail.yourdomain.com ~all` |
| TXT | `mail._domainkey` | `<DKIM_KEY>` |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@yourdomain.com` |

**Important:** Set the PTR (reverse DNS) record for your VPS IP to `mail.yourdomain.com` in your VPS provider's control panel.

#### Managing Email Accounts

```bash
# Add email account
ssh root@<VPS_IP> "podman exec -it mailserver setup email add user@yourdomain.com"

# List email accounts
ssh root@<VPS_IP> "podman exec mailserver setup email list"

# Generate DKIM key
ssh root@<VPS_IP> "podman exec mailserver setup config dkim"
```

### VPS Git Sync

After initial deployment, VPS servers automatically sync configuration from git:

```bash
# Config is cloned to /etc/nixos-config on first rebuild
# Auto-sync runs hourly via systemd timer

# Manual sync
ssh root@<VPS_IP> "systemctl start nixos-config-sync.service"

# Check sync status
ssh root@<VPS_IP> "systemctl status nixos-config-sync.timer"
```

**Workflow:**
1. Edit config locally and push to GitHub
2. VPS auto-pulls and rebuilds hourly (or trigger manually)

## Configuration

Edit `config.nix` to customize your setup:

```nix
{
  # Darwin (macOS)
  darwinUsername = "your-username";
  darwinHostname = "your-mac-hostname";
  darwinEnableTilingWM = true;  # aerospace, sketchybar

  # Workstation (NixOS) — Asus Vivobook laptop
  workstationVivobookUsername = "your-username";
  workstationVivobookHostname = "vivobook";
  workstationVivobookEnableTilingWM = true;  # hyprland, waybar, wofi

  # Workstation (NixOS) — desktop PC
  workstationPcUsername = "your-username";
  workstationPcHostname = "pc";
  workstationPcEnableTilingWM = true;  # hyprland, waybar, wofi

  # VPS - Hostinger
  vpsHostingerUsername = "your-username";
  vpsHostingerHostname = "your-vps-hostname";
  vpsHostingerIP = "your-vps-ip";
  vpsHostingerGateway = "your-gateway-ip";

  # ACME (Let's Encrypt)
  acmeEmail = "your-email@example.com";

  # VPS - DigitalOcean
  vpsDigitalOceanUsername = "your-username";
  vpsDigitalOceanHostname = "your-droplet-hostname";

  # Development tools
  enableLaravel = true;  # PHP, Composer, MySQL, PostgreSQL, Redis
  enableRust = true;     # Rust toolchain (rustup)
  enableVolta = true;    # Node.js version manager

  # SSH public keys
  sshKeys = [
    "ssh-ed25519 AAAAC3Nza... user@example.com"
  ];
}
```

### Configuration Options

| Option | Platform | Description |
|--------|----------|-------------|
| `darwinUsername` | macOS | Your macOS username |
| `darwinHostname` | macOS | Machine hostname |
| `darwinEnableTilingWM` | macOS | Enable aerospace/sketchybar |
| `workstationVivobookUsername` | Workstation | Vivobook laptop username |
| `workstationVivobookHostname` | Workstation | Vivobook hostname |
| `workstationVivobookEnableTilingWM` | Workstation | Enable hyprland/waybar/wofi |
| `workstationPcUsername` | Workstation | Desktop PC username |
| `workstationPcHostname` | Workstation | Desktop PC hostname |
| `workstationPcEnableTilingWM` | Workstation | Enable hyprland/waybar/wofi |
| `vpsHostingerUsername` | VPS | Hostinger VPS username |
| `vpsHostingerHostname` | VPS | Hostinger VPS hostname |
| `vpsHostingerIP` | VPS | Hostinger static IP address |
| `vpsHostingerGateway` | VPS | Hostinger gateway IP |
| `vpsDigitalOceanUsername` | VPS | DigitalOcean username |
| `vpsDigitalOceanHostname` | VPS | DigitalOcean hostname |
| `acmeEmail` | VPS | Email for Let's Encrypt SSL certificates |
| `enableLaravel` | macOS | Enable PHP/Laravel stack |
| `enableRust` | macOS | Enable Rust toolchain |
| `enableVolta` | macOS | Enable Volta (Node.js manager) |
| `sshKeys` | All | SSH public keys for authorized access |

## Usage

### macOS

```bash
# Rebuild
sudo darwin-rebuild switch --flake .#mrscraper

# Or use the helper
nix develop --command rebuild
```

### Workstation

```bash
# Rebuild (pick the machine: vivobook or pc)
sudo nixos-rebuild switch --flake .#vivobook
sudo nixos-rebuild switch --flake .#pc

# Or use the helper in dev shell
nix develop --command rebuild
```

## Keybindings

### macOS (AeroSpace)

| Key | Action |
|-----|--------|
| `Cmd + Enter` | Open Ghostty |
| `Cmd + 1-9` | Switch workspace |
| `Cmd + Shift + 1-9` | Move window to workspace |
| `Cmd + h/j/k/l` | Focus window |
| `Cmd + Shift + h/j/k/l` | Swap windows |
| `Cmd + Shift + f` | Toggle fullscreen |
| `Cmd + t` | Toggle float |

### Workstation (Hyprland)

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + h/j/k/l` | Focus window |
| `Super + Shift + h/j/k/l` | Move window |
| `Super + d` | Open Wofi |
| `Super + q` | Close window |

### Neovim

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>e` | Toggle file tree |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover docs |
| `<leader>ca` | Code action |

### Tmux

| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix key |
| `prefix + \|` | Vertical split |
| `prefix + -` | Horizontal split |
| `prefix + h/j/k/l` | Navigate panes |

## Shell Aliases

| Alias | Command |
|-------|---------|
| `v` | nvim |
| `t` | tmux startup script |
| `gs` | git status |
| `ga` | git add |
| `gc` | git commit |
| `gp` | git push |
| `ls` | eza --icons |
| `ll` | eza -la --icons |
| `cat` | bat |

## License

MIT
