# SSH (home)

Client-side SSH config.

## authorized_keys is NOT managed here

Deliberately. home-manager would write `~/.ssh/authorized_keys` as a
`/nix/store` symlink, and sshd's `StrictModes` rejects that with:

```
bad ownership or modes for directory /nix/store
```

Inbound keys are set via `users.users.<name>.openssh.authorizedKeys.keys` in
`../../darwin/default.nix`, which populates
`/etc/ssh/nix_authorized_keys.d/${username}` — read by sshd as root through
`AuthorizedKeysCommand`.
