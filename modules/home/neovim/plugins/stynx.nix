{ pkgs, ... }:
let
  # Shared source for both the editor plugin and the `stynx` CLI it drives.
  stynxSrc = pkgs.fetchFromGitHub {
    owner = "maulanasdqn";
    repo = "stynx-code";
    rev = "ec17dec07bca14df44284c51feeb5c59cc3210c9";
    hash = "sha256-AWKSeiC/tkR2XdBr46rdI0QVNVF8eUaj7tnSJSEVOb8=";
  };

  # The `stynx` binary (workspace member `stynx-code`) the plugin shells out to.
  stynx-cli = pkgs.rustPlatform.buildRustPackage {
    pname = "stynx";
    version = "3.12.1";
    src = stynxSrc;

    cargoHash = "sha256-SMcbuY6qozez95b8TwCO6i1ZhTyOziIvlG+wFP+Y/R4=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    cargoBuildFlags = [ "-p" "stynx-code" ];
    doCheck = false;

    meta = {
      description = "stynx-code — interactive AI coding assistant";
      homepage = "https://github.com/maulanasdqn/stynx-code";
      mainProgram = "stynx";
    };
  };

  # The Neovim plugin, living in the stynx-code-nvim/ subdir of the repo.
  stynx-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "stynx-code-nvim";
    version = "3.12.1";
    src = stynxSrc + "/stynx-code-nvim";
  };
in
{
  programs.nixvim = {
    extraPlugins = [ stynx-nvim ];

    # Put `stynx` on Neovim's PATH so the plugin's job runner can find it.
    extraPackages = [ stynx-cli ];

    extraConfigLua = ''
      -- Run after the plugin's own deferred setup so this config wins.
      vim.schedule(function()
        require("stynx").setup({
          binary = "${stynx-cli}/bin/stynx",
        })
      end)
    '';
  };
}
