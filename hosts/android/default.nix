{
  config,
  pkgs,
  ...
}:

{
  environment.packages = with pkgs; [
    git
    curl
    wget
    jq
    ripgrep
    fd
    fzf
    bat
    htop
    tmux
    openssh
    zsh
    starship
  ];

  environment.etcBackupExtension = ".bak";

  build.activationBefore.fixNixEnvPty = ''
    mkdir -p /tmp/nix-env-compat
    cat > /tmp/nix-env-compat/nix-env << 'EOF'
    #!/bin/sh
      exec ${config.nix.package}/bin/nix-env "$@" </dev/null 1>/dev/null
    EOF
    chmod +x /tmp/nix-env-compat/nix-env
    export PATH="/tmp/nix-env-compat:$PATH"
  '';

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "24.05";
}
