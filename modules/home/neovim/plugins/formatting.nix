{ ... }:
{
  programs.nixvim.plugins = {
    conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          php = [ "php_cs_fixer" ];
          javascript = [ "prettierd" ];
          typescript = [ "prettierd" ];
          javascriptreact = [ "prettierd" ];
          typescriptreact = [ "prettierd" ];
          astro = [ "prettierd" ];
          rust = [ "rustfmt" ];
          css = [ "prettierd" ];
          scss = [ "prettierd" ];
          html = [ "prettierd" ];
          json = [ "prettierd" ];
          yaml = [ "prettierd" ];
          markdown = [ "prettierd" ];
          nix = [ "nixfmt" ];
          lua = [ "stylua" ];
        };

        format_on_save = {
          lsp_fallback = true;
          async = false;
          timeout_ms = 2000;
        };
      };
    };

    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true;
        ts_config = {
          lua = [ "string" ];
          javascript = [ "template_string" ];
          typescript = [ "template_string" ];
          php = [ "string" ];
        };
      };
    };

    typescript-tools = {
      enable = true;
      settings = {
        settings = {
          separate_diagnostic_server = true;
          publish_diagnostic_on = "insert_leave";
          tsserver_file_preferences = {
            includeInlayParameterNameHints = "all";
            includeInlayFunctionParameterTypeHints = true;
            includeInlayVariableTypeHints = true;
            includeInlayPropertyDeclarationTypeHints = true;
            includeInlayFunctionLikeReturnTypeHints = true;
          };
        };
      };
    };
  };
}
