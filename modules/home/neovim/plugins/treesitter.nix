{ ... }:
{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        # No ensure_installed: with nixGrammars all parsers ship via Nix.
        # A runtime list makes nvim-treesitter git-clone/compile parsers at
        # startup — blocks first draw for minutes under proot (honor), and
        # mdx/swift can never install (no parser / needs tree-sitter CLI).
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
