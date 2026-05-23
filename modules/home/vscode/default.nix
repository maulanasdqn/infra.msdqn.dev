{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          mvllow.rose-pine
          catppuccin.catppuccin-vsc-icons

          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          golang.go
          ms-python.python
          ms-python.vscode-pylance
          bradlc.vscode-tailwindcss
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode

          eamodio.gitlens
          mhutchie.git-graph

          usernamehw.errorlens
          christian-kohler.path-intellisense
          formulahendry.auto-rename-tag
          formulahendry.auto-close-tag

          yzhang.markdown-all-in-one
          redhat.vscode-yaml
          tamasfe.even-better-toml
        ];

        userSettings = {
          "workbench.colorTheme" = "Rosé Pine";
          "workbench.iconTheme" = "catppuccin-mocha";

          "workbench.colorCustomizations" = {
            "[Rosé Pine]" = {
              "titleBar.activeBackground" = "#c4a7e7";
              "titleBar.activeForeground" = "#191724";
              "titleBar.inactiveBackground" = "#1f1d2e";
              "activityBarBadge.background" = "#c4a7e7";
              "activityBarBadge.foreground" = "#191724";
              "statusBar.background" = "#c4a7e7";
              "statusBar.foreground" = "#191724";
              "statusBar.debuggingBackground" = "#eb6f92";
              "statusBar.noFolderBackground" = "#1f1d2e";
              "tab.activeBorderTop" = "#c4a7e7";
              "editorCursor.foreground" = "#ebbcba";
              "editorLineNumber.activeForeground" = "#c4a7e7";
              "progressBar.background" = "#c4a7e7";
              "focusBorder" = "#c4a7e7";
              "inputOption.activeBorder" = "#c4a7e7";
              "button.background" = "#c4a7e7";
              "button.foreground" = "#191724";
              "badge.background" = "#c4a7e7";
              "badge.foreground" = "#191724";
            };
          };

          "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Fira Code', monospace";
          "editor.fontSize" = 14;
          "editor.fontLigatures" = true;
          "editor.lineHeight" = 1.6;

          "editor.smoothScrolling" = true;
          "editor.cursorBlinking" = "smooth";
          "editor.cursorSmoothCaretAnimation" = "on";
          "editor.minimap.enabled" = false;
          "editor.renderWhitespace" = "selection";
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = "active";
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.wordWrap" = "on";

          "window.titleBarStyle" = "custom";
          "window.menuBarVisibility" = "toggle";

          "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
          "terminal.integrated.fontSize" = 13;

          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";

          "git.autofetch" = true;
          "git.confirmSync" = false;

          "telemetry.telemetryLevel" = "off";
        };
      };
    };

    home.packages = with pkgs; [
      nil
      nixpkgs-fmt
    ];
  };
}
