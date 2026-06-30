{ username, enableLaravel, lib, ... }:
{
  home-manager.users.${username}.programs.zsh.shellAliases = {
    c = "clear";
    v = "nvim";
    t = "~/.local/bin/tmux-startup";
    cl = "claude";
    build-system = "sudo nix run nix-darwin -- switch --flake ~/.config/nix";

    ss = "ls -t ~/Desktop/*.png 2>/dev/null | head -1";

    # Mirror an Android device borderless and at the same height as iPhone
    # Mirroring's largest zoom (898px window). scrcpy can't draw rounded corners
    # or a phone frame, so borderless is the closest "phone-screen" look. Width
    # follows the device aspect ratio; `command` skips the alias to avoid loops.
    scrcpy = "command scrcpy --window-borderless --window-height 898";

    init-laravel = "cp ~/.config/nix/templates/laravel/{flake.nix,.envrc} . && direnv allow";
    init-nodejs = "cp ~/.config/nix/templates/nodejs/{flake.nix,.envrc} . && direnv allow";
    init-rust = "cp ~/.config/nix/templates/rust/{flake.nix,.envrc} . && direnv allow";

    ls = "eza --icons";
    ll = "eza -la --icons";
    la = "eza -a --icons";
    lt = "eza --tree --icons";
    l = "eza -l --icons";
    cat = "bat";

    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gco = "git checkout";
    gcb = "git checkout -b";
  } // lib.optionalAttrs enableLaravel {
    pa = "php artisan";
    pas = "php artisan serve";
    pam = "php artisan migrate";
    pamfs = "php artisan migrate:fresh --seed";
    ci = "composer install";
    cu = "composer update";
  };
}
