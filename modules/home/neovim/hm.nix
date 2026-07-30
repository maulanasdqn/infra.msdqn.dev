{
  pkgs,
  nixvim,
  ...
}:
{
  # Reusable neovim config (editor + LSP). Imported by the NixOS/Darwin wrapper
  # (./default.nix, which also adds stynx) and directly by nix-on-droid/honor.
  imports = [
    nixvim.homeModules.nixvim
    ./options.nix
    ./keymaps.nix
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    version.enableNixpkgsReleaseCheck = false;

    # Build against the host's `pkgs` instead of letting Nixvim import its own
    # Nixpkgs instance. Without this, Nixvim constructs a second instance from
    # its `inputs.nixpkgs` — which our flake `follows`, so it lands on the same
    # revision anyway, just evaluated twice and without allowUnfree or our
    # overlays. Nixvim warns about exactly that follows-vs-pin mismatch and asks
    # for either the follows to be dropped or `nixpkgs.source` to be pinned;
    # reusing the host pkgs settles it without a duplicate instance.
    #
    # This is also what keeps honor correct: that host builds pkgs from
    # nixpkgs-stable (see the honor entry in flake.nix), so Nixvim inherits
    # neovim 0.11 from 25.11 rather than 0.12/glibc 2.42, which freezes at TUI
    # startup under proot. The nixvim-stable input stays for the module set; this
    # option is what makes the *package* follow the host.
    nixpkgs.useGlobalPackages = true;

    extraPackages = with pkgs; [
      ripgrep
      fd
      prettierd
      stylua
      nixfmt
      eslint_d
    ];
  };
}
