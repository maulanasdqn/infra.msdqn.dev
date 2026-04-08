{ username, pkgs, ... }:
{
  home-manager.users.${username}.programs.nixvim = {
    extraPackages = with pkgs; [
      phpactor
      php83Packages.php-cs-fixer
      phpstan

      typescript-language-server
      vscode-langservers-extracted
      eslint

      astro-language-server

      rust-analyzer
      clippy
    ];

    plugins = {
      lsp = {
        enable = true;
        servers = {
          lua_ls = {
            enable = true;
            settings = {
              Lua = {
                workspace.checkThirdParty = false;
                telemetry.enable = false;
                diagnostics.globals = [ "vim" ];
              };
            };
          };

          nil_ls.enable = true;

          phpactor = {
            enable = true;
            settings = {
              language_server_phpstan.enabled = true;
              language_server_psalm.enabled = false;
            };
          };

          ts_ls = {
            enable = true;
            settings = {
              typescript = {
                inlayHints = {
                  includeInlayParameterNameHints = "all";
                  includeInlayParameterNameHintsWhenArgumentMatchesName = false;
                  includeInlayFunctionParameterTypeHints = true;
                  includeInlayVariableTypeHints = true;
                  includeInlayPropertyDeclarationTypeHints = true;
                  includeInlayFunctionLikeReturnTypeHints = true;
                  includeInlayEnumMemberValueHints = true;
                };
              };
              javascript = {
                inlayHints = {
                  includeInlayParameterNameHints = "all";
                  includeInlayParameterNameHintsWhenArgumentMatchesName = false;
                  includeInlayFunctionParameterTypeHints = true;
                  includeInlayVariableTypeHints = true;
                  includeInlayPropertyDeclarationTypeHints = true;
                  includeInlayFunctionLikeReturnTypeHints = true;
                  includeInlayEnumMemberValueHints = true;
                };
              };
            };
          };

          eslint.enable = true;

          taplo.enable = true;

          tailwindcss = {
            enable = true;
            filetypes = [
              "html"
              "css"
              "scss"
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
              "astro"
            ];
          };
          cssls.enable = true;

          html.enable = true;
          emmet_ls = {
            enable = true;
            filetypes = [
              "html"
              "css"
              "scss"
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
              "php"
              "blade"
              "astro"
            ];
          };

          jsonls.enable = true;

          astro = {
            enable = true;
            settings = {
              typescript = {
                tsdk = "./node_modules/typescript/lib";
              };
            };
          };
        };

        keymaps = {
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
            "K" = "hover";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
          };
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
        };
      };

      lspsaga = {
        enable = true;
        settings = {
          lightbulb.enable = false;
          symbol_in_winbar.enable = true;
          ui = {
            border = "rounded";
            code_action = "💡";
          };
        };
      };

      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            on_attach = "__lspOnAttach";
            settings = {
              rust-analyzer = {
                checkOnSave.command = "clippy";
                cargo.allFeatures = true;
              };
            };
          };
        };
      };
    };
  };
}
