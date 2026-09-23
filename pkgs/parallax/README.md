# parallax

Nix derivation for [Parallax](https://github.com/maulanasdqn/parallax), a
multi-protocol SOCKS5/HTTP proxy server written in Rust.

Built from source using `rustPlatform.buildRustPackage` with `fetchFromGitHub`.
The binary is `parallax-server`.

## Updating

Bump `rev` and `hash` (source) plus `cargoHash` (dependencies) when the upstream
repo changes:

```sh
nix-prefetch-url --unpack "https://github.com/maulanasdqn/parallax/archive/<new-rev>.tar.gz"
nix hash to-sri --type sha256 <output>
```

Then build with a dummy `cargoHash` to get the real one from the error output.
