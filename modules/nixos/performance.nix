{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ----------------------------------------------------------------------------
  # Workstation performance tuning
  #
  # CPU note: this machine uses amd-pstate-epp in "active" mode with the
  # "balance_performance" energy-performance preference, which is already the
  # recommended setup for Zen3 laptops. We intentionally do NOT pin the governor
  # to "performance" — on a laptop that just raises temps/fan noise and throttles
  # sooner without faster sustained throughput. Leave amd-pstate to do its job.
  # ----------------------------------------------------------------------------

  # Faster rebuilds: pull prebuilt binaries instead of compiling from source.
  # msdqn.cachix.org caches the personal project flakes (personal-website, hpyd,
  # rag-app, …); nix-community caches a large swath of the wider ecosystem.
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://msdqn.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "msdqn.cachix.org-1:I5z8egjNf2iKYLwLGF2REfpELlFoUdaSLsh7dQk1a+o="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # zram: fast, compressed in-RAM swap. Sits at higher priority than the on-disk
  # swapfile, so the machine reaches for compressed RAM before touching the SSD.
  # Coexists with the on-disk swap that hibernate still relies on.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # 38GB RAM -> ~9.5GB compressed swap headroom
    priority = 100;
  };

  # Hardware video acceleration (VAAPI) on the Vega iGPU. Offloads video decode
  # from the CPU — the single biggest CPU win for a browser-heavy workload.
  # The radeonsi VAAPI driver already ships with mesa; this adds the runtime
  # libs and `vainfo` for verification.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  environment.systemPackages = with pkgs; [
    libva-utils # `vainfo` to confirm hardware decode is live
  ];

  # Help browsers/Electron/Wayland clients use the iGPU decoder.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  boot.kernel.sysctl = {
    # 38GB RAM: prefer keeping pages resident over swapping. zram makes the rare
    # swap cheap, but there is no reason to swap aggressively at 60.
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # Dev file watchers (vite, cargo-watch, tsc --watch, LSPs) exhaust the
    # default inotify limits on large repos. Raise them generously.
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 8192;

    # Electron/Chromium and some games need a high mmap count.
    "vm.max_map_count" = 2147483642;
  };
}
