{ username, pkgs, ... }:
{
  home-manager.users.${username}.programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "claudecode-nvim";
        version = "0-unstable";
        src = pkgs.fetchFromGitHub {
          owner = "coder";
          repo = "claudecode.nvim";
          rev = "6091df0e8edcdc92526cec23bbb42f63c0bb5ff2";
          hash = "sha256-PmSYIE7j9C2ckJc9wDIm4KCozXP0z1U9TOdItnDyoDQ=";
        };
      })
    ];

    extraConfigLua = ''
      require("claudecode").setup({
        auto_start = true,
        port_range = { min = 10000, max = 65535 },
        terminal = {
          split_side = "right",
          split_width_percentage = 0.4,
          provider = "native",
        },
        diff_opts = {
          auto_close_on_accept = true,
          show_diff_stats = true,
        },
      })

      vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude Code" })
      vim.keymap.set("n", "<leader>cs", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })
      vim.keymap.set("v", "<leader>cs", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
      vim.keymap.set("n", "<leader>co", "<cmd>ClaudeCodeOpen<cr>", { desc = "Open Claude Code" })
      vim.keymap.set("n", "<leader>cx", "<cmd>ClaudeCodeClose<cr>", { desc = "Close Claude Code" })
    '';

    opts.autoread = true;

    autoCmd = [
      {
        event = [ "FocusGained" "BufEnter" "CursorHold" "CursorHoldI" ];
        pattern = [ "*" ];
        command = "if mode() != 'c' | checktime | endif";
      }
    ];
  };
}
