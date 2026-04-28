{ username, ... }:
{
  home-manager.users.${username}.programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixGrammars = false;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        ensure_installed = [
          "astro"
          "css"
          "html"
          "javascript"
          "typescript"
          "tsx"
        ];
      };
    };

    ts-autotag.enable = true;

    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 3;
        trim_scope = "outer";
      };
    };
  };
}
