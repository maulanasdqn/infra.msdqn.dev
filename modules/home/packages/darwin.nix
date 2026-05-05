{
  pkgs,
  lib,
  username,
  enableRust,
  enableVolta,
  enableGolang,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = with pkgs;
      [
        ripgrep
        fd
        fzf
        eza
        bat
        htop
        jq
        tree
        bun
        slack
        speedtest-cli
        k6
        ffmpeg
        zig
        zls
        cmake
        ninja
        meson
        pkg-config
        ccache
        bear
      ]
      ++ lib.optionals enableRust [ rustup ]
      ++ lib.optionals enableVolta [ volta ]
      ++ lib.optionals enableGolang [ go gopls ];

    home.sessionVariables =
      {
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        DB_SQLITE_POOL_SIZE = "4";
        N8N_RUNNERS_ENABLED = "true";
        N8N_BLOCK_ENV_ACCESS_IN_NODE = "false";
        N8N_GIT_NODE_DISABLE_BARE_REPOS = "true";
        N8N_CUSTOM_EXTENSIONS = "$HOME/Development/mrscraper/n8n-nodes-mrscraper";
      }
      // lib.optionalAttrs enableRust {
        RUSTUP_HOME = "$HOME/.rustup";
        CARGO_HOME = "$HOME/.cargo";
      }
      // lib.optionalAttrs enableVolta {
        VOLTA_HOME = "$HOME/.volta";
      }
      // lib.optionalAttrs enableGolang {
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
      };

    home.sessionPath =
      [
        "$HOME/.bun/bin"
        "$HOME/.npm-global/bin"
      ]
      ++ lib.optionals enableRust [ "$HOME/.cargo/bin" ]
      ++ lib.optionals enableVolta [ "$HOME/.volta/bin" ]
      ++ lib.optionals enableGolang [ "$HOME/go/bin" ];
  };
}
