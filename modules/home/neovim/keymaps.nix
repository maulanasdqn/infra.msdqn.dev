{ ... }:
{
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>nh"; action = ":nohl<CR>"; options = { silent = true; desc = "Clear search"; }; }
    { mode = "n"; key = "<leader>f"; action = ":NvimTreeToggle<CR>"; options = { silent = true; desc = "Toggle file tree"; }; }
    { mode = "n"; key = "<leader>t"; action = ":Lspsaga term_toggle<CR>"; options = { silent = true; desc = "Toggle terminal"; }; }
    { mode = "n"; key = "f"; action = ":Lspsaga goto_definition<CR>"; options = { silent = true; desc = "Go to definition"; }; }
    { mode = "n"; key = "Q"; action = ":Lspsaga code_action<CR>"; options = { silent = true; desc = "Code action"; }; }
    { mode = "n"; key = "e"; action = ":Lspsaga diagnostic_jump_next<CR>"; options = { silent = true; desc = "Next diagnostic"; }; }
    { mode = "n"; key = "E"; action = ":Lspsaga diagnostic_jump_prev<CR>"; options = { silent = true; desc = "Prev diagnostic"; }; }
    { mode = "n"; key = "F"; action = ":Lspsaga peek_definition<CR>"; options = { silent = true; desc = "Peek definition"; }; }
    { mode = "n"; key = "D"; action = ":Lspsaga hover_doc<CR>"; options = { silent = true; desc = "Hover doc"; }; }
    { mode = "n"; key = "<leader>s"; action = "<CMD>Telescope find_files<CR>"; options = { desc = "Find files"; }; }
    { mode = "n"; key = "<leader>S"; action = "<CMD>Telescope live_grep<CR>"; options = { desc = "Live grep"; }; }
    { mode = "n"; key = "<leader>b"; action = "<CMD>Telescope buffers<CR>"; options = { desc = "Buffers"; }; }
    {
      mode = ["n" "v"];
      key = "<leader>mp";
      action.__raw = ''
        function()
          require("conform").format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 1000,
          })
        end
      '';
      options = { desc = "Format file or range"; };
    }
  ];
}
