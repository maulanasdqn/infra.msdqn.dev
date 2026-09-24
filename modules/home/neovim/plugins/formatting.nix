{ ... }:
{
  programs.nixvim.plugins = {
    conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          php = [ "php_cs_fixer" ];
          javascript = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          typescript = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          javascriptreact = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          typescriptreact = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          json = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          astro = [ "prettierd" ];
          rust = [ "rustfmt" ];
          css = [ "prettierd" ];
          scss = [ "prettierd" ];
          html = [ "prettierd" ];
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

        formatters = {
          "biome-check" = {
            require_cwd = true;
          };
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
