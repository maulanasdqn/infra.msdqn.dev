# git

`home.stateVersion` is < 25.05, so the git module still defaults
`signing.format` to `"openpgp"`. It is set explicitly here to silence the
deprecation warning. No signing key is configured, so the setting is inert —
it exists purely to keep the build output clean.
