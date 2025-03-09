# Runbooks

## Disk is full

This mostly happens on the VM because the disk image is so small.

The nix store tends to grow quite a bit as updates happen. At some point the disk fills up and needs cleaning up. It's a simple as cleaning up the nix store.

You'll need run `df -h` to see how full the disk is.

First, run the nix gc: `nix store gc -v`. That will likely not clean up as much as you want but it's a start.

If you still need space, you can clean up old generations from nixos:

1. Run `nixos-rebuild list-generations` to see what generations are available
1. Clean them up with `sudo nix-collect-garbage ...`
  - Passing `--delete-old` deletes everything but the current generation. Use with care.
  - Passing `--delete-older-than <period>` lets you specify stuff old than some time period
