{ ... }:
{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        ensure_installed = [
          # JS/TS family
          "javascript"
          "typescript"
          "tsx"
          "jsdoc"
          "json"
          "jsonc"
          "graphql"
          "mdx"
          "svelte"
          "vue"
          "prisma"
          # Web
          "astro"
          "css"
          "scss"
          "html"
          # Other
          "swift"
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
