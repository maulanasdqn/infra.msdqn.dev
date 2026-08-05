{ ... }:
{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;

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
