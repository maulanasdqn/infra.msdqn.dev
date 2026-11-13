# Neovim plugins

`default.nix` is the shared plugin set (editor UX + LSP), safe on mobile.

## lsp.nix — sourcekit-lsp is Darwin-only

The Swift/ObjC server's `cmd` points at the Xcode toolchain's `sourcekit-lsp`,
which only exists on macOS. It is gated behind Darwin because on the Linux hosts
(vivobook, pc, wsl, honor) the server would fail to spawn on every swift or objc
buffer.

## treesitter.nix — no `ensure_installed`

With `nixGrammars`, every parser ships via Nix.

A runtime list makes nvim-treesitter git-clone and compile parsers at startup.
That blocks the first draw for minutes under proot on nix-on-droid, and `mdx` /
`swift` can never install at all — no parser available, and it needs the
tree-sitter CLI.

## lsp.nix — biome is enabled globally

`biome` only attaches in projects that have a `biome.json` or `biome.jsonc`
(nvim-lspconfig's `root_pattern` for the server), so enabling it for every host
costs nothing in repos that do not use Biome.

## formatting.nix — biome-check before prettierd

JS, TS, JSX, TSX and JSON try `biome-check` first and fall through to
`prettierd`, with `stop_after_first` so only one formatter ever runs.

`require_cwd = true` on `biome-check` is what makes the fallthrough work.
biome-check ships a `cwd` finder that locates the nearest `biome.json` /
`biome.jsonc`, but `require_cwd` defaults to `false`, which means conform still
treats the formatter as available when that finder comes up empty — it would run
biome-check and error in every non-Biome repo instead of moving on to prettierd.

## lsp.nix — `checkJs` for loose JavaScript

`ts_ls` sets `implicitProjectConfiguration.checkJs = true`. Plain `.js` files
outside a `jsconfig.json` / `tsconfig.json` project otherwise get only syntax
errors: DOM typos (`document.getElementByid`) and possibly-null elements from
`querySelector` go unreported. With it, they are type-checked against `lib.dom`
like TypeScript.

It only applies to inferred projects. A repo with its own `jsconfig.json` or
`tsconfig.json` keeps its own `checkJs` setting.

## lsp.nix — formatters live in `extraPackages`

`prettierd` and `stylua` are referenced by `formatting.nix` and must be in
`extraPackages`, which puts them on nvim's PATH. Without them, conform silently
skips HTML, CSS, SCSS, YAML, Markdown, Astro and Lua, and falls back to LSP
formatting (or nothing) on save.

## No typescript-tools

`ts_ls` is the only TypeScript/JavaScript server. typescript-tools.nvim was
removed: it looks for `tsserver` in the project's `node_modules` or a global npm
install, and neither exists on these machines, so it raised `Cannot find
tsserver executable` on every JS/TS buffer outside a project. Running both would
also duplicate completions and diagnostics.
