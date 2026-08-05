# Docker / Colima

Colima deliberately does **not** start at login — that burns a VM's worth of RAM
every session for something usually idle. Start it on demand:

```sh
colima-up
```

An idle auto-stop launchd agent complements this, shutting the VM down after a
period of inactivity. An idle Colima VM was previously holding ~4 GB.
