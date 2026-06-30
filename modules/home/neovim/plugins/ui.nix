{ ... }:
{
  programs.nixvim.plugins = {
    web-devicons.enable = true;

    noice = {
      enable = true;
      settings = {
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          hover.enabled = true;
          signature.enabled = true;
          progress.enabled = true;
        };
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
          inc_rename = false;
          lsp_doc_border = true;
        };
        routes = [
          {
            filter = {
              event = "msg_show";
              any = [
                { find = "%d+L, %d+B"; }
                { find = "; after #%d+"; }
                { find = "; before #%d+"; }
                { find = "%d fewer lines"; }
                { find = "%d more lines"; }
                { find = "written"; }
                { find = "search hit BOTTOM"; }
                { find = "search hit TOP"; }
                { find = "E486"; }
              ];
            };
            opts.skip = true;
          }
          {
            filter = {
              event = "lsp";
              kind = "progress";
            };
            opts.skip = true;
          }
          {
            filter.event = "notify";
            view = "mini";
          }
        ];
        views = {
          cmdline_popup = {
            position = {
              row = 5;
              col = "50%";
            };
            size = {
              width = 60;
              height = "auto";
            };
          };
          popupmenu = {
            relative = "editor";
            position = {
              row = 8;
              col = "50%";
            };
            size = {
              width = 60;
              height = 10;
            };
            border = {
              style = "rounded";
              padding = [ 0 1 ];
            };
            win_options = {
              winhighlight = {
                Normal = "Normal";
                FloatBorder = "DiagnosticInfo";
              };
            };
          };
        };
      };
    };

    notify = {
      enable = true;
      settings = {
        background_colour = "#000000";
        fps = 60;
        render = "default";
        timeout = 3000;
        top_down = true;
      };
    };

    nvim-tree = {
      enable = true;
      settings = {
        disable_netrw = true;
        hijack_netrw = true;
        respect_buf_cwd = true;
        sync_root_with_cwd = true;
        view = {
          relativenumber = true;
          float = {
            enable = true;
            open_win_config.__raw = ''
              function()
                local HEIGHT_RATIO = 0.8
                local WIDTH_RATIO = 0.3
                local screen_w = vim.opt.columns:get()
                local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                local window_w = screen_w * WIDTH_RATIO
                local window_h = screen_h * HEIGHT_RATIO
                local window_w_int = math.floor(window_w)
                local window_h_int = math.floor(window_h)
                local center_x = (screen_w - window_w) / 2
                local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
                return {
                  border = "rounded",
                  relative = "editor",
                  row = center_y,
                  col = center_x,
                  width = window_w_int,
                  height = window_h_int,
                }
              end
            '';
          };
          width.__raw = ''
            function()
              return math.floor(vim.opt.columns:get() * 0.3)
            end
          '';
        };
        filters.custom = [ "^.git$" ];
        renderer.indent_width = 1;
      };
    };
  };
}
