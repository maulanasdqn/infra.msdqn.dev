{ ... }:
{
  imports = [
    ./aliases.nix
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "docker"
        "tmux"
      ];
      extraConfig = ''
        ZSH_DISABLE_COMPFIX=true
        DISABLE_AUTO_UPDATE=true
        DISABLE_MAGIC_FUNCTIONS=true
        ZSH_TMUX_AUTOSTART=false
        ZSH_TMUX_AUTOCONNECT=true
        ZSH_TMUX_FIXTERM=false
        ZSH_TMUX_CONFIG="$HOME/.config/tmux/tmux.conf"
      '';
    };

    initContent = ''
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/.moon/bin:$PATH"
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
