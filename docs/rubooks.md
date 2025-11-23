# Runbooks

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
