# Code

## CLI

```sh
sudo -iu forgejo forgejo ...
```

## Restore backup

```sh
# Find the backup
standard-backups list-backups {dest}
# ... pick the right backup id ...

# Extract the files
standard-backups restore-backup {dest} {id} /tmp/forgejo-restore

# Start a clean Forgejo
systemctl stop forgejo # avoids conflicts
systemctt start systemd-tmpfiles-resetup # creates base file structure

# Copy the files over
cp \
    --recursive \
    --preserve=mode,timestamps \
    --target-directory /var/lib/forgejo/ \
    /tmp/forgejo-restore/var/lib/forgejo/*
chmod -R forgejo:forgejo /var/lib/forgejo

# Restart the service
systemctl restart forgejo-secrets # restart matters here
systemctl restart forgejo

# Run a healthcheck
sudo -iu forgejo forgejo doctor check --all
```
