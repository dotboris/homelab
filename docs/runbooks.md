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

## Replicate backups

```sh
# enter the sops shell
nix run .#sops-shell homelab

# export variables for ease of use
set local_password (echo "$secrets" | jq -r .backups.repos.local.password)
set b2_password (echo "$secrets" | jq -r .backups.repos.backblaze.password)
set b2_key_id (echo "$secrets" | jq -r .backups.repos.backblaze.keyId)
set b2_key (echo "$secrets" | jq -r .backups.repos.backblaze.key)

# init repository with the right chunker params (only do this one)

# backblaze
RESTIC_PASSWORD=$b2_password \
RESTIC_FROM_PASSWORD=$b2_password \
B2_ACCOUNT_ID=$b2_key_id \
B2_ACCOUNT_KEY=$b2_key \
restic init \
  -r ~/Backups/homelab-replica/backblaze \
  --from-repo b2:dotboris-homelab-backups \
  --copy-chunker-params

# local (currently broken)
RESTIC_PASSWORD=$local_password \
RESTIC_FROM_PASSWORD=$local_password \
restic init \
  -r ~/Backups/homelab-replica/local \
  --from-repo sftp://homelab.lan//var/lib/homelab-backups/repos/local \
  --copy-chunker-params

# copy snapshots

# backblaze
RESTIC_PASSWORD=$b2_password \
RESTIC_FROM_PASSWORD=$b2_password \
B2_ACCOUNT_ID=$b2_key_id \
B2_ACCOUNT_KEY=$b2_key \
restic copy \
  -r ~/Backups/homelab-replica/backblaze \
  --from-repo b2:dotboris-homelab-backups

# local (currently broken)
RESTIC_PASSWORD=$local_password \
RESTIC_FROM_PASSWORD=$local_password \
restic copy \
  -r ~/Backups/homelab-replica/local \
  --from-repo sftp://homelab.lan//var/lib/homelab-backups/repos/local
```
